_    = require 'lodash'
Path = require 'path'

self = {
  typeName: (filepath) ->
    file = Path.basename filepath
    file = _.first file.split '.'
    _.upperFirst _.camelCase file

  inputTypeName: (name) ->
    ret = self.typeName name
    "#{ret}Input"
}
module.exports = _.extend { _ }, self
