GridFw = require '..'
app = new GridFw()


app.get '/', (ctx)->
	console.log '---- exec ', ctx.url
	ctx.send 'Main page'

app.get 'test/path', (ctx)->
	console.log '---- exec ', ctx.url
	ctx.send 'Hello word'

app.get 'test/:k', (ctx)->
	console.log 'Got param k=', ctx.params.k
	ctx.send 'k value: '+ ctx.params.k

app.use (ctx)->
	console.log '---- execute middleware 1'
app.use '/test', (ctx)->
	console.log '---- execute middleware 2'

app.listen 3000