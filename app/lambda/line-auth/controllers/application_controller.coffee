class ApplicationController
  index: (event)->
    console.log ' -- application index --'
    console.log event
    {}

module.exports = ApplicationController