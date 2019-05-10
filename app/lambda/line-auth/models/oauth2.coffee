{ _, sha256_uuid } = require '../utils'
axios     = require 'axios'
AppModel  = require './application_model'

LINE_CHANNEL_ID     = process.env.LINE_CHANNEL_ID
LINE_CHANNEL_SECRET = process.env.LINE_CHANNEL_SECRET

LINE_SCOPES         = 'profile openid email'

getCredential = (tokenHost) -> {
  client: {
    id: LINE_CHANNEL_ID
    secret: LINE_CHANNEL_SECRET
  }
  auth: {
    authorizePath: '/oauth2/v2.1/authorize'
    tokenHost: tokenHost
    tokenPath: '/oauth2/v2.1/token'
  }
  options: {
    authorizationMethod: 'body'
  }
}

class Oauth2 extends AppModel
  @getOauth2: ->
    require('simple-oauth2').create getCredential 'https://access.line.me'
    
  @getAuthorizationUri: ({ redirect_uri }) ->
    @getOauth2().authorizationCode.authorizeURL _.extend { redirect_uri }, {
      scope: LINE_SCOPES
      state: sha256_uuid()
    }

  @getAccessToken: (code, state, { redirect_uri }) ->
    oauth2 = require('simple-oauth2').create getCredential 'https://api.line.me'
    
    tokenConfig = _.extend { code, redirect_uri }, {
      scope: LINE_SCOPES
    }

    result = await oauth2.authorizationCode.getToken tokenConfig
    oauth2.accessToken.create result
    
module.exports = Oauth2