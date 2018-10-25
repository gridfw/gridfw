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

# serve a single file
app.get '/favicon.ico', app.static path.join __dirname, 'public/gridfw.svg'
# serve a folder
app.get '/public/*', app.static path.join __dirname, 'public'
# equiv to
# app.get '/public/*', app.static 'public'

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
	console.log '--- params: ', ctx.params
	console.log '--- query: ', ctx.query
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
		console.log '--- raw params: ', ctx.rawParams
		console.log '--- params: ', ctx.params
		console.log '---- param[mm] ', ctx.params.mm
		console.log '---- param[p] ', ctx.params.p
		ctx.send 'builder works'


app.get '/asterix/*', (ctx)->
	console.log '--- raw params: ', ctx.params
	ctx.info 'asterix', 'hello khalid'
	ctx.send 'hello khalid'


# run the server at port 3000
app.listen 3000
	.then -> app.log 'Main', "Server listening At: #{app.port}"
	.catch (err)-> app.error 'Main', "Got Error: ", err

# wrap test
app.wrap '/*', (controller)->
	console.log '---- exec wra^p'
	(ctx)->
		console.log '---- my wrap'
		app.log 'myWrap', "--- wraping: #{ctx.method} #{ctx.url}"
		await controller ctx
		app.log 'myWrap', "--- ENDS: #{ctx.method} #{ctx.url}"