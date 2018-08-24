_     = require 'lodash'
axios = require 'axios'
btoa  = require 'btoa'
{ GraphQLClient } = require 'graphql-request'

APPSYNC_API_ENDPOINT = "https://w5rkt62unbe7podinjvnlfplcu.appsync-api.ap-southeast-1.amazonaws.com/graphql"
APPSYNC_API_KEY = "da2-2uvtb3kiybh57kr4bl6omql3f4"

main = ->
  query = """
    mutation ($data: String!){
      addEvent(input: {data: $data}){
        data
      }
    }
  """
  client = new GraphQLClient APPSYNC_API_ENDPOINT,
    headers:
      'x-api-key': APPSYNC_API_KEY

  data = await client.request query,
    data: '234'
  console.log '--result---'
  console.log data

main()
