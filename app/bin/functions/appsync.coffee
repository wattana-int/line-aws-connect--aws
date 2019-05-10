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

APPSYNC_BASE_DIR    = _.get(process, 'env.APPSYNC_BASE_DIR', '/app/appsync')

self = {
  appsync_s3_schema: (aUUID, aStackName, aName) ->
    bucketName = self.samDeployBucketName aStackName
    appsyncSchemaFile = "appsync-#{aUUID}-#{aName}"
    "s3://#{bucketName}/#{appsyncSchemaFile}"

  appsync_s3_template: (aUUID, aStackName, aName) ->
    bucketName = self.samDeployBucketName aStackName
    appsyncTemplateFile = "#{aUUID}-#{aStackName}-appsync-#{_.lowerCase aName}.yml"
    "s3://#{bucketName}/#{appsyncTemplateFile}"

  cmd_schema: (aName) ->
    console.log '########################################################################'
    console.log "### --- #{aName} --- ###"
    console.log ''
    console.log await require('/app/appsync/schema')(Path.join APPSYNC_BASE_DIR, aName)
    console.log '########################################################################'

  upload_appsync_scheme: (uuid, aStackName, aBucketName, aAppsyncPath) ->
    schema = await require('/app/appsync/schema') aAppsyncPath
    name   = _.upperFirst _.camelCase Path.basename(aAppsyncPath)

    s3file =
      "s3://#{aBucketName}/#{uuid}-#{aStackName}" +
      "-appsync-#{_.lowerCase Path.basename aAppsyncPath}-schema.yml"

    schema_file =
      Path.join '/tmp', Path.basename(s3file)

    template_file = Path.join aAppsyncPath, 'output', 'template.yml'
    template_s3_file =
      "s3://#{aBucketName}/#{uuid}-#{aStackName}" +
      "-appsync-#{_.lowerCase Path.basename aAppsyncPath}-template.yml"

    console.log 'write schema to -> ', schema_file
    await fs.writeFileAsync schema_file, schema
    console.log "Upload schema to #{s3file}"

    await do_cmd 'aws', [
      's3'
      'cp'
      schema_file
      s3file
    ], "Uploading AppSync Scheme to S3 (#{aAppsyncPath})"
    
    await do_cmd(
      'aws',
      ['s3', 'cp', template_file, template_s3_file],
      "Uploading AppSync Template to S3 (#{aAppsyncPath})"
    )
    Promise.resolve { s3file, name }
}
module.exports = self