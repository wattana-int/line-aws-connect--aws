_         = require 'lodash'
sha256    = require 'sha256'
uuidv4    = require 'uuid/v4'
Promise   = require 'bluebird'
{ spawn } = require('child_process')

self = 
  sha256_uuid: -> sha256 uuidv4()
  do_cmd: (cmd, params, desc, aOpts = {})->
    opts = {}
    opts = _.extend opts, aOpts
    console.log '-----------------------------'.bold
    console.log desc.bold.yellow
    console.log cmd.green + ' ' + params.join(' ')
    console.log ''
    new Promise (resolve, reject)->
      errors = []
      
      p = spawn cmd, params, opts
      p.stdout.on 'data', (data)-> console.log "stdout: ".green, data.toString()
      p.stderr.on 'data', (data)-> errors.push data.toString()
      p.on 'exit', -> if _.isEmpty errors then resolve() else reject(errors.join("\n"))

module.exports = self