GridFw = require '..'

app = new GridFw()


app.get '/', (ctx)->
	console.log '--- test cookie'
	console.log '--- cookie: ', ctx.cookies

	# set cookie
	dt = Date.now()
	ctx.cookie 'simple', 'cc:' + dt
	ctx.cookie 'json', {datestamp: dt}
	ctx.cookie 'boolean', true
	ctx.cookie 'Number', 123

	ctx.send 'cookie value: ' + ctx.cookies.simple

app.listen 3000