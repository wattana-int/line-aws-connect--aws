require("util").inspect.defaultOptions.depth = null

_       = require 'lodash'
Path    = require 'path'
glob    = require "glob"
Promise = require 'bluebird'
yaml    = require 'js-yaml'

fs = Promise.promisifyAll require('fs')
fsx = require 'fs-extra'

{
  GraphQLSchema
  GraphQLObjectType
  GraphQLString
  printSchema
  introspectionFromSchema
} = require 'graphql'

removeAwsSubscriptionTemplateDummy = (str)->
  str = str.replace /type\W.*\s.*@aws_subscribe.*\s*.*}.*\s*\s\s/g, ''
  str.replace /"""/g, '#'

fillMappingTemplates = (aMappingTemplates, aType, aField, aMappingType, aTemplate)->
  if aTemplate 
    _.set aMappingTemplates, "#{aType}.#{aField}.#{aMappingType}", aTemplate
    
getQueries = (aMappingTemplates, filesPath)->
  ret = {}

  files = await new Promise (resolve, reject)-> 
    glob filesPath, (err, files)-> 
      if err then reject(err) else resolve(files)

  files = files.filter (f)-> Path.extname(f) in ['.coffee', '.js']
  files = files.map (file)->
    name    = if file.endsWith '.coffee' 
                _.camelCase Path.basename file, '.coffee'
              else
                _.camelCase Path.basename file, '.js'

    module  = require(file) # name

    typeName = Path.basename Path.dirname file 

    fillMappingTemplates aMappingTemplates, (_.upperFirst typeName), name, 'DataSourceName', module.DataSourceName
    fillMappingTemplates aMappingTemplates, (_.upperFirst typeName), name, 'RequestMappingTemplate', module.RequestMappingTemplate
    fillMappingTemplates aMappingTemplates, (_.upperFirst typeName), name, 'ResponseMappingTemplate', module.ResponseMappingTemplate
    
    _.extend {name},
      module: module
  
  files = _.keyBy files, 'name'
  _.mapValues files, (v)-> v.module

getSubscriptions = (aMappingTemplates, filesPath, mutations)->
  ret = {}
  
  files = await new Promise (resolve, reject)-> 
    glob filesPath, (err, files)-> 
      if err then reject(err) else resolve(files)

  files = files.filter (f)-> Path.extname(f) in ['.coffee', '.js']
  files = files.map (file)->
    name    = if file.endsWith '.coffee' 
                _.camelCase Path.basename file, '.coffee'
              else
                _.camelCase Path.basename file, '.js'

    module = require(file) name
    
    if _.isArray module.aws_mutations
      aws = module.aws_mutations.map (e)->
        require Path.join(Path.dirname(file), "../mutation/#{e}")

        mutationName = _.camelCase Path.basename e
        
        mutation: mutations[mutationName]
        mutationName: mutationName

      mutationNames = aws.map (e)-> e.mutationName
                         .join '", "'
    
    { name, module }
    
  files = _.keyBy files, 'name'
  _.mapValues files, (v)-> v.module  
  
#module.exports = ->
fetchSchema = (dir)->
  mappingTemplates = {}
  queries       = await getQueries        mappingTemplates, Path.join(dir, 'schema/query/*')
  mutations     = await getQueries        mappingTemplates, Path.join(dir, 'schema/mutation/*')
  subscriptions = await getSubscriptions  mappingTemplates, Path.join(dir, 'schema/subscription/*'), mutations
  # console.log '--- queries ---------'
  # console.log queries
  # console.log '--- mutations -------'
  # console.log mutations
  # console.log '--- subscriptions ---'
  # console.log subscriptions
  # console.log '---------------------'
  schema = new GraphQLSchema
    query: new GraphQLObjectType
      name: 'Query'
      fields: queries

    mutation: new GraphQLObjectType
      name: 'Mutation'
      fields: mutations

    subscription: new GraphQLObjectType
      name: 'Subscription'
      fields: subscriptions

  { schema, mappingTemplates }

writeMappingTemplates = (aPath, aMappingTemplate)->
  ###
    AppSyncMutationSendMessageResolver:
    Type: AWS::AppSync::Resolver
    DependsOn:
      - AppSyncScheme
    Properties:
      ApiId: !GetAtt AppSyncApi.ApiId
      TypeName: Mutation
      FieldName: sendMessage
      DataSourceName: !GetAtt AppSyncSendMesageDataSource.Name
      RequestMappingTemplate: |
        {
          "version": "2017-02-28",
          "payload": {
            "userid": "${context.arguments.input.userid}",
            "message": "${context.arguments.input.message}"
          }
        }
      ResponseMappingTemplate: |
        $util.toJson($context.result)

  ###
  resolvers = {}
  appSyncName = _.upperFirst _.camelCase Path.basename aPath
  templateFile = Path.join aPath, 'output', "template.yml"

  for eachType, fields of aMappingTemplate
    for eachField, types of fields
      resolverName = "AppSync#{appSyncName}#{_.upperFirst eachType}#{_.upperFirst eachField}Resolver"
       
      _.set resolvers, resolverName,
          Type: "AWS::AppSync::Resolver"
          DependsOn: ["AppSync#{appSyncName}Schema"]
          Properties:
            ApiId: 
              "Fn::GetAtt": "AppSync#{appSyncName}Api.ApiId"
            TypeName: eachType
            FieldName: eachField
            
      for eachMappingType, template of types
        _.set resolvers, "#{resolverName}.Properties.#{eachMappingType}", template
        
  templateData = yaml.safeDump resolvers, noCompatMode: true
   
  fs.writeFileSync templateFile, templateData

module.exports = (path)->
  { schema, mappingTemplates } = await fetchSchema path
  
  sdlString = removeAwsSubscriptionTemplateDummy printSchema schema

  mutations     = await getQueries        {}, Path.join(path, "schema/mutation/*")
  subscriptions = await getSubscriptions  {}, Path.join(path, "schema/subscription/*"), mutations
  
  sdlines = sdlString.split "\n"
  
  subscriptionEdit = {}
  for eachSubscriptionName, data of subscriptions
    if _.isArray(data.aws_mutations) and !_.isEmpty(data.aws_mutations)
      mutationNames = _(data.aws_mutations).map (e)-> _.camelCase e
                                           .value()

      subscriptionEdit[eachSubscriptionName] = "@aws_subscribe(mutations: [\"#{mutationNames.join(', ')}\"])"
  
  edited = []
  lines = []

  for eachLine, idx in sdlines
    added = false
    for n, val of subscriptionEdit
      if eachLine.startsWith "  #{n}"
        unless n in edited
          edited.push n
          lines.push eachLine
          added = true
          lines.push "  #{val}\n"
    
    lines.push eachLine unless added
  
  ret = lines.join "\n"
  ## write to schema.graphql
  schemaFile = Path.join path, 'output', 'schema.graphql'
  fsx.ensureDirSync(Path.dirname schemaFile)
  fs.writeFileSync schemaFile, ret

  await writeMappingTemplates path, mappingTemplates

  ret

# main = ->
#   raw = await fetchSchema()
#   console.log removeAwsSubscriptionTemplateDummy printSchema raw
#   #console.log printSchema raw
#   console.log '--- OK ---'

# main()