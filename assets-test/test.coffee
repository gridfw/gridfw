###
# test gridfw
###
GridFw = require '..'
path = require 'path'

# create server
app = new GridFw() # default options

# params
app.param
	name: 'user'
	matches: /[0-9]/
	resolver: (value, paramType, ctx)->
		ctx.info 'Params', value
		# find & return user
		{_id: 111, name: 'Wijdane', gender: 'F'}



app.get '/hello/:user', (ctx) ->
	app.log 'Route', 'Hello world from morocco!'
	ctx.info 'Params', ' ---- params ---- ', ctx.params
	ctx.info 'Query', ' ---- Query ---- ', ctx.query
	ctx.send ctx.params.user

app.all '/sweet-route', (ctx) ->
	ctx.info 'Route', 'sweet'
	ctx.send 'all'

# run the server
app.listen 3000
	.then -> app.log 'Main', "Server listening At: #{app.port}"
	.catch (err)-> app.error 'Main', "Got Error: ", err