{ sha256_uuid } = require '../utils'

class ApplicationController
  sha256_uuid: sha256_uuid
  index: (event)->
    console.log ' -- application index --'
    console.log event
    {}

module.exports = ApplicationController