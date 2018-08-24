_         = require 'lodash'
sha256    = require 'sha256'
uuidv4    = require 'uuid/v4'

btoa      = require 'btoa'
{ GraphQLClient } = require 'graphql-request'

APPSYNC_API_ENDPOINT  = process.env.APPSYNC_API_ENDPOINT
APPSYNC_API_KEY       = process.env.APPSYNC_API_KEY

self =
  sha256_uuid: -> sha256 uuidv4()
  getRedirectUri: (event)->
    "https://#{event.headers.Host}/Prod/callback"

  sendEvent: (aData)->
    data = btoa aData
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

    client.request query, { data }

module.exports = _.extend { _ }, self