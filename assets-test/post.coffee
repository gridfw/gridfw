GridFw = require '..'
app = new GridFw()
NativeFs = require 'fs'
fs		= require 'mz/fs'
Path	= require 'path'

app.get '/', -> 'post'

app.post '/', (ctx)->
	console.log '--->>>>>>>>>>> header: ', ctx.reqHeaders['content-type']
	# console.log '--- got data: ', ctx.req
	dt= Date.now()
	data = await ctx.upload
		timeout: 2000
		# onFile: (filename, file, fieldname, encoding, mimetype) ->
		# 	console.log '---->>>> ', 'file traite'
		# 	fpath = Path.join __dirname, filename
		# 	# file.pipe NativeFs.createWriteStream fpath

		# 	return fpath

	console.log '---- timeout: ', Date.now() - dt, 'ms'
	console.log '---- data: ', data
	ctx.send 'data received'

app.listen 3000