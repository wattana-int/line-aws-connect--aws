
{ _, getRedirectUri, sendEvent } = require '../utils'

ApplicationController = require './application_controller'
Oauth2Model = require '../models/oauth2'

class Klass extends ApplicationController
  index: (event)->
    redirect_uri = getRedirectUri event
    { queryStringParameters } = event
    { code, state } = queryStringParameters
    accessToken = await Oauth2Model.getAccessToken code, state, { redirect_uri }
    console.log '- access token -'
    console.log accessToken
    await sendEvent JSON.stringify accessToken
    "Thank you."

module.exports = Klass