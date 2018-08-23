{ _, getRedirectUri } = require '../utils'
ApplicationController = require './application_controller'

Oauth2Model = require '../models/oauth2'

class Klass extends ApplicationController
  index: (event)->
    redirect_uri = getRedirectUri event
    authorizationUri = Oauth2Model.getAuthorizationUri {redirect_uri}

    { authorizationUri }

module.exports = Klass