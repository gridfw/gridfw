###
Hello world
###

GridFw = require '..'
path = require 'path'
# GridMonit = require '../../gridfw-monitor'

# create server
app = new GridFw path.join __dirname, 'gridfw-config.js'

# add plugin
# app.plugin GridMonit()

# append Get route
app.get '/', (ctx)->
	ctx.info 'My service', '--- Path "/" called'
	ctx.send 'Hello world'

# test GET
app.get '/hello/world', (ctx)->
	ctx.info 'My service', "---- got #{ctx.path}"
	ctx.send 'hello dear'

app.get '/hello world', (ctx)->
	ctx.info 'My service', "---- got #{ctx.path}"
	ctx.send 'hi'

# dynamic route
app.get '/test/:var/:var2', (ctx)->
	console.log '--- gotin'
	ctx.send 'got great results'

# dynamic route
app.get '/test hello/:var/:var2', (ctx)->
	console.log '--- gotin'
	ctx.send 'got great results'

# test of route builder
app.get '/builder/:mm/:p'
	.param 'p', /^\d+$/, (ctx, data)->
		ctx.info 'myService', 'Resolve param "p"'
		ctx.debug 'myService', 'data: ', data
		return 'ppppmmmm-----'
	.then (ctx)->
		console.log '---- param[mm] ', ctx.params.mm
		console.log '---- param[p] ', ctx.params.p
		ctx.send 'builder works'


# run the server at port 3000
app.listen 3000
	.then -> app.log 'Main', "Server listening At: #{app.port}"
	.catch (err)-> app.error 'Main', "Got Error: ", err
