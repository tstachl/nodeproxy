express    = require 'express'
path       = require 'path'
fs         = require 'fs'
stitch     = require 'stitch'
request    = require 'request'
port       = process.env.PORT or 5000
env        = process.env.NODE_ENV or 'development'
server     = express.createServer()
publicPath = "#{__dirname}/public"
index      = "#{publicPath}/index.html"
desk       = stitch.createPackage
  paths: ["#{__dirname}/desk"]
  dependencies: ["#{__dirname}/lib/sfconn.js"]
sfconn     = stitch.createPackage
  dependencies: ["#{__dirname}/lib/sfconn.js"]



server.configure ->
  # standard
  server.use express.logger()
  server.use express.errorHandler()
  server.use express.methodOverride()
  # override body
  server.use ((req, res, next) ->
    data = ''
    req.setEncoding 'utf8'
    req.on 'data', (chunk) ->
      data += chunk
    
    req.on 'end', ->
      console.log data
      req.body = data
      next()
  )
  
  # routing
  server.use server.router
  server.use express.static publicPath

server.get '/', (req, rsp) ->
  rsp.contentType index
  rsp.sendfile index

server.get '/sfconn.js', sfconn.createServer()
server.get '/assets/sfconn.js', sfconn.createServer()
server.get '/assets/desk.js', desk.createServer()

server.all '/', (req, rsp) ->
  rsp.header 'Access-Control-Allow-Origin', '*'
  rsp.header 'Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
  rsp.header 'Access-Control-Allow-Headers', req.header('Access-Control-Request-Headers')
  rsp.header 'Access-Control-Max-Age', '1728000'  
  return rsp.send 200 if req.method == 'OPTIONS'
  
  options = {}
  options.headers = {}
  for key, value of req.headers
    if key == 'accept-encoding'
      continue
    options.headers[key.charAt(0).toUpperCase() + key.substr(1)] = req.headers[key]
  
  console.log '************** REQUEST HEADERS: ', options.headers
  
  options.url = req.headers.proxy
  options.method = if req.method == 'PUT' then 'PATCH' else req.method
  options.body = req.body
  
  console.log '************** REQUEST METHOD: ' + options.method
  console.log '************** REQUEST URL: ' + options.url
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