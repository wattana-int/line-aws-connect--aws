

Mincer = require('mincer')
Mincer.Template.libs["coffee"] = require("coffeescript")

assets = require 'connect-assets'

express = require 'express'
app = express()

app.set 'view engine', 'pug', { pretty: true }
app.locals.pretty = true;
console.log('--> ', __dirname)

app.use assets
  compress: false
  build: true
  buildDir: '../../tmp'
  paths: [
    '/var/task/assets'
  ]

{ _, getRedirectUri, sendEvent } = require './utils'
Oauth2Model = require './models/oauth2'

app.get '/', (req, res) ->
  res.render 'index', { title: 'Line Auth ..', user: '' }

app.get '/login_uri', (req, res)->
  redirect_uri = getRedirectUri req
  authorizationUri = Oauth2Model.getAuthorizationUri {redirect_uri}

  res.json { authorizationUri }

app.get '/callback', (req, res)->

  redirect_uri = getRedirectUri req

  { code, state } = req.query

  try
    accessToken = await Oauth2Model.getAccessToken code, state, { redirect_uri }
    console.log '- access token -'
    console.log accessToken
    await sendEvent JSON.stringify accessToken

    res.render 'callback', { title: 'Line Auth ..', user: '' }
  catch e
    error = e.message
    res.json {redirect_uri, error}

  

module.exports = app