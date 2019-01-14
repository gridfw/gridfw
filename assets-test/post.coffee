GridFw = require '..'
app = new GridFw()


app.get '/', -> 'post'

app.post '/', (ctx)->
	console.log '--- header: ', ctx.reqHeaders['content-type']
	# console.log '--- got data: ', ctx.req
	dt= Date.now()
	data = await ctx.upload()
	console.log '---- timeout: ', Date.now() - dt, 'ms'
	console.log '---- data: ', data.body
	ctx.send 'data received'

app.listen 3000