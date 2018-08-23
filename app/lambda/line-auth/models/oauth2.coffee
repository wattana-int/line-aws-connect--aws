{ _, sha256_uuid } = require '../utils'
axios     = require 'axios'
AppModel  = require './application_model'

LINE_CHANNEL_ID     = process.env.LINE_CHANNEL_ID
LINE_CHANNEL_SECRET = process.env.LINE_CHANNEL_SECRET

LINE_SCOPES         = 'profile openid email'

credentials =
  client: 
    id: LINE_CHANNEL_ID
    secret: LINE_CHANNEL_SECRET
  auth:
    authorizePath: '/oauth2/v2.1/authorize'
    tokenHost: 'https://access.line.me'
    tokenPath: '/oauth2/v2.1/token'
  options:
    authorizationMethod: 'body'

oauth2 = require('simple-oauth2').create credentials

class Oauth2 extends AppModel
  @getOauth2: ->
    oauth2

  @getAuthorizationUri: ({redirect_uri})->
    oauth2.authorizationCode.authorizeURL _.extend { redirect_uri },
      scope: LINE_SCOPES
      state: sha256_uuid()

  @getAccessToken: (code, state, { redirect_uri })->
    c = _.extend {}, credentials
    c.auth.tokenHost = 'https://api.line.me'

    oauth2 = require('simple-oauth2').create c
    
    tokenConfig = _.extend { code, redirect_uri },
      scope: LINE_SCOPES

    console.log 'tokenConfig: ', tokenConfig

    result = await oauth2.authorizationCode.getToken tokenConfig
    console.log '-> ', result
    oauth2.accessToken.create result
    
module.exports = Oauth2