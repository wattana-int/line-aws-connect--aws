{ 
  _
  inputTypeName 
} =  require '../../../const'

{
  GraphQLString
  GraphQLNonNull
  GraphQLBoolean
  GraphQLInputObjectType
} = require 'graphql'

module.exports = #(name)->
  type: require('../../types/event')
  args:
    input:
      type: require('../../types/input/event_input')
  DataSourceName: 
    "Fn::GetAtt": "AppSyncDemoAddEventDataSource.Name"
  RequestMappingTemplate: """
    {
      "version": "2017-02-28",
      "payload": {
        "data": "${context.arguments.input.data}"
      }
    }
  """
  ResponseMappingTemplate: """
    $util.toJson($context.result)
  """