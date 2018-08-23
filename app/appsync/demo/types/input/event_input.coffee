require("util").inspect.defaultOptions.depth = null

CONST = require '../../../const'

{
  GraphQLSchema
  GraphQLInputObjectType
  GraphQLString
  GraphQLNonNull
  GraphQLInt
  GraphQLList
} = require 'graphql'

module.exports = new GraphQLInputObjectType
  name: CONST.typeName __filename
  fields: ->
    data: type: new GraphQLNonNull GraphQLString