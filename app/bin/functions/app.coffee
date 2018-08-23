_         = require 'lodash'
util      = require 'util'
color     = require 'colors'
Path      = require 'path'
AWS       = require 'aws-sdk'
Promise   = require 'bluebird'
fs        = Promise.promisifyAll require 'fs'
fsx       = require 'fs-extra'
promptly  = require 'promptly'
fg        = require 'fast-glob'

{ spawn } = require('child_process')
exec      = util.promisify require('child_process').exec


{ 
  table
} =  require 'table'

{ do_cmd, sha256_uuid } = require './utils'

LAMBDA_BASE_DIR     = _.get(process, 'env.LAMBDA_BASE_DIR', '/app/lambda')
APPSYNC_BASE_DIR    = _.get(process, 'env.APPSYNC_BASE_DIR', '/app/appsync')

self = 
  samTmpPackedFile: (aUUID)-> "/tmp/#{aUUID}.yaml"
  samDeployBucketName: (aStackName)->
    "#{aStackName}--tmp-deployment"
    'ans-tmp-deployment'

  appsync_s3_schema: (aUUID, aStackName, aName)-> 
    bucketName = self.samDeployBucketName aStackName
    appsyncSchemaFile = "appsync-#{aUUID}-#{aName}"
    "s3://#{bucketName}/#{appsyncSchemaFile}"

  appsync_s3_template: (aUUID, aStackName, aName)->
    bucketName = self.samDeployBucketName aStackName
    appsyncTemplateFile = "#{aUUID}-#{aStackName}-appsync-#{_.lowerCase aName}.yml"
    "s3://#{bucketName}/#{appsyncTemplateFile}"

  cmd_appsync_schema: (aName)->
    console.log '########################################################################'
    console.log "### --- #{aName} --- ###"
    console.log ''
    console.log await require('/app/appsync/schema')(aName)
    console.log '########################################################################'

  upload_appsync_scheme: (aUUID, aStackName, aName)->
    schema = await require('/app/appsync/schema')(aName)
    name   = _.upperFirst _.camelCase Path.basename(aName)

    s3file = self.appsync_s3_schema aUUID, aStackName, name

    schema_file       = Path.join '/tmp', Path.basename(s3file)  
    template_file     = Path.join aName, 'output', 'template.yml'
    template_s3_file  = self.appsync_s3_template aUUID, aStackName, name 

    console.log 'write schema to -> ', schema_file
    await fs.writeFileAsync schema_file, schema
    console.log "Upload schema to #{s3file}"

    await do_cmd 'aws', [
      's3'
      'cp'
      schema_file
      s3file
    ], "Uploading AppSync Scheme to S3 (#{aName})"
    
    await do_cmd 'aws', ['s3', 'cp', template_file, template_s3_file], "Uploading AppSync Template to S3 (#{aName})"

    Promise.resolve {s3file, name}

  deploy_cloud_formation: (aUUID, aStackName)->
    tmpfile = self.samTmpPackedFile aUUID
    params = [
      'cloudformation'
      'deploy'
      '--stack-name'
      aStackName
      '--template-file'
      tmpfile
      '--capabilities'
      'CAPABILITY_NAMED_IAM'
      '--parameter-overrides'
      "StackName=#{aStackName}"
      "DeploymentUUID=#{aUUID}"
    ]

    do_cmd 'aws', params, 'Deploying with CloundFormation.'

  validate_template: (template_file)->
    cmd = 'aws'
    params = [
      'cloudformation'
      'validate-template'
      '--template-body'
      "file://#{template_file}"
    ]
    do_cmd cmd, params, 'Validating Template File'
     
  cmd_deploy: (cmd)->
    uuid = sha256_uuid()
    stackName = process.env.STACK_NAME
    templateFile = '/app/template.yml'

    await self.validate_template templateFile
    
    await self.npm_install_for_lambda()
    
    await self.cmd_sam_package uuid, stackName, templateFile, cmd

    #appsyncs = await fg '*', { cwd: APPSYNC_BASE_DIR, onlyDirectories: true }
    
    #appSyncSchemas = await Promise.mapSeries appsyncs, (appsyncName)->
    #  self.upload_appsync_scheme aUUID, aStackName, Path.join(APPSYNC_BASE_DIR, appsyncName)
    
    await self.deploy_cloud_formation uuid, stackName

  npm_install_for_lambda: ->

    dirs = await fg '*/package.json', { cwd: LAMBDA_BASE_DIR, onlyDirectories: false }
    console.log dirs
    lambdas = dirs.map (e)-> Path.dirname e

    x = await Promise.mapSeries lambdas, (lambda)->
      node_modules_dir = Path.join LAMBDA_BASE_DIR, lambda, 'node_modules'
      cmd = "rm -rf #{Path.join node_modules_dir, '*'}"
      console.log cmd
      { stdout, stderr } = await exec cmd
      dir = Path.dirname node_modules_dir
      await do_cmd 'npm', ['install'], "NPM install for lambda function. (#{dir})", { cwd: dir }
      lambda

    x
  cmd_sam_package: (aUUID, aStackName, aTemplateFile, cmd)->
    bucketName = self.samDeployBucketName aStackName
    tmpfile = self.samTmpPackedFile aUUID

    cmd = 'sam'
    params = [
      'package',
      '--template-file', 
      aTemplateFile,
      '--output-template-file',
      tmpfile,
      '--s3-bucket',
      bucketName
    ]
    do_cmd cmd, params, 'Packing Lambda Function'
        
module.exports = self