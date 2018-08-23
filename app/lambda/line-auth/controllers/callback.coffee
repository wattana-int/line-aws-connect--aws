ApplicationController = require './application_controller'
class Klass extends ApplicationController
  index: (event)->
    console.log '-callback-index'
    {}


module.exports = Klass