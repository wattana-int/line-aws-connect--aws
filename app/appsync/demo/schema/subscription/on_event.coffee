{
  GraphQLSchema
  GraphQLObjectType
  GraphQLString
  GraphQLList
  GraphQLNonNull
} = require 'graphql'

module.exports = ->
  type: require('../../types/event')
  aws_mutations: [
    'add_event'
  ]