{ _, getRedirectUri } = require '../utils'

ApplicationController = require './application_controller'
Oauth2Model = require '../models/oauth2'

class Klass extends ApplicationController
  index: (event)->
    redirect_uri = getRedirectUri event
    { queryStringParameters } = event
    { code, state } = queryStringParameters
    Oauth2Model.getAccessToken code, state, { redirect_uri }

module.exports = Klass