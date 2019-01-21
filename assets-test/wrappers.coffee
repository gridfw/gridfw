GridFw = require '..'
app = new GridFw()


app.get '/', (ctx)->
	console.log '---- exec ', ctx.url
	await new Promise (resolve)-> setTimeout resolve, 5000
	ctx.send 'Main page'

app.get 'test/path', (ctx)->
	console.log '---- exec ', ctx.url
	ctx.send 'test path'

app.get 'test/:k', (ctx)->
	console.log 'Got param k=', ctx.params.k
	ctx.send 'k value: '+ ctx.params.k

# app.use (ctx)->
# 	console.log '---- execute middleware 1'
# app.use '/test', (ctx)->
# 	console.log '---- execute middleware 2'

app.listen 3000

# handler wrappers
app.wrap (ctx, next)->
	console.log '---- handler wrapper at: ', ctx.path
	await next()
	console.log '---- ends call'

app.wrap (ctx, next)->
	console.log '--- wrapper 2'
	await next()
	console.log '--- ends wrapper 2'

# route wrapper
app.wrap '/', (ctx, next)->
	console.log '=====> / wrap'
	v = await next()
	console.log '=====> end / wrap'
	return v
app.wrap '/test', (ctx, next)->
	console.log '===========> /test wrap'
	v = await next()
	console.log '===========> end /test wrap'
	return v

console.log '------ ', app.mode