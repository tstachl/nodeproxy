express    = require 'express'
path       = require 'path'
fs         = require 'fs'
request    = require 'request'
port       = process.env.PORT or 9294
env        = process.env.NODE_ENV or 'development'
server     = express.createServer()
publicPath = "#{__dirname}/public"
index      = "#{publicPath}/index.html"

server.configure ->
  # standard
  server.use express.logger()
  server.use express.errorHandler()
  server.use express.bodyParser()
  server.use express.methodOverride()
  
  # routing
  server.use server.router
  server.use express.static publicPath

server.get '/', (req, rsp) ->
  rsp.contentType index
  rsp.sendfile index

server.all '/', (req, rsp) ->
  rsp.header 'Access-Control-Allow-Origin', '*'
  rsp.header 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
  rsp.header 'Access-Control-Allow-Headers', req.header('Access-Control-Request-Headers')
  rsp.header 'Access-Control-Max-Age', '1728000'
  
  console.log '************** RESPONSE HEADERS: ', rsp.headers
  
  rsp.send 200 if req.method == 'OPTIONS'
  
  options = {}
  options.headers = {}
  for key, value of req.headers
    continue if key.indexOf 'accept-' == 0
    options.headers[key.charAt(0).toUpperCase() + key.substr(1)] = req.headers[key]
  
  
  console.log '************** REQUEST HEADERS: ', options.headers
  
  options.url = req.headers.proxy
  options.method = if req.method == 'PUT' then 'PATCH' else req.method
  
  console.log '************** REQUEST METHOD: ' + options.method
  console.log '************** REQUEST URL: ' + options.url
  
  unless isEmptyObject req.body
    if req.headers['content-type'].indexOf('x-www-form') != -1
      options.body = serialize(req.body)
    else
      options.body = JSON.stringify req.body
    
    console.log '************** REQUEST BODY: ' + options.body
  
  request options, (e, r, body) ->
    console.log '************** RESPONSE HEADERS: ', r.headers
    console.log '************** RESPONSE STATUS: ' + r.statusCode
    if body
      console.log '************** RESPONSE BODY: ' + body
      rsp.send body, r.headers, r.statusCode
    else
      rsp.send r.headers, r.statusCode

server.listen port, ->
  console.log "Server listening on port #{port}"

###
# HELPER
###
isEmptyObject = (obj) ->
  for name of obj
    no
  yes

serialize = (obj) ->
  str = []
  for key, value of obj
    str.push "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"
  str.join '&'