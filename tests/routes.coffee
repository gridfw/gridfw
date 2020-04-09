###*
 * Routes test
###
Gridfw= require '../..'

app= new Gridfw({
	i18nMapper: ''
	})

# COMMON CONTROLLER
cntrlCb= (ctx)->
	console.log 'ROUTE ---->>', ctx.route
	console.log '---- URL: ', ctx.url
	console.log '---- PATH: ', ctx.pathname
	console.log '---- QUERY: ', ctx.query
	console.log '---- PARAMS: ', ctx.params
	ctx.end "CALL TO: #{ctx.url}"

# params
app
.param 'param1'
.param 'param2'
.param 'param3'
.param 'param4', /^\d+$/

# ROUTES
app.get '/', cntrlCb
app.get '/a/b/c', cntrlCb
app.get '/a/:param1/c', cntrlCb
app.get '/hello/:param2/cc/:param3', cntrlCb
app.get '/*', cntrlCb
# app.get '/*/value', cntrlCb
app.get '/*param4', cntrlCb

app.listen()
	.catch (err)-> app.fatalError 'APP', err

console.log 'APP>>', app