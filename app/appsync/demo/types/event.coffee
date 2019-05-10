CONST = require '../../const'

{
  GraphQLSchema
  GraphQLNonNull
  GraphQLObjectType
  GraphQLList
  GraphQLInt
  GraphQLString
} = require 'graphql'

module.exports = new GraphQLObjectType {
  name: CONST.typeName __filename
  fields: -> {
    data: {
      type: new GraphQLNonNull GraphQLString
    }
  }
}