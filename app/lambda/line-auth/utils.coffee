_         = require 'lodash'
sha256    = require 'sha256'
uuidv4    = require 'uuid/v4'

self =
  sha256_uuid: -> sha256 uuidv4()
  getRedirectUri: (event)->
    "https://#{event.headers.Host}/Prod/callback"
    
module.exports = _.extend { _ }, self