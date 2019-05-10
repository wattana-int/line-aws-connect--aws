_ = require 'lodash'
self = {
  klass: ({ path }) ->
    name = path
    name = path.slice(1) if path.startsWith '/'
    m = require "./controllers/#{name}_controller"
    new m()

  select: (event) ->
    body = switch event.httpMethod
      when 'GET'
        await self.klass(event).index event
        
      else
        { success: true }
    {
      statusCode: 200
      body: JSON.stringify body
    }
}

module.exports = self
      