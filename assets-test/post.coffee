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
	fpath = 
	data = await ctx.upload
		progress: (received, totalReceived, total)->
			console.log "---->> #{received} :: #{totalReceived} :: #{total}"
		# timeout: 2000
		# filePath: (fName) ->
		# 	console.log '---- fname ----', fName
		# 	Path.join __dirname, 'bb.pdf'

	console.log '---- timeout: ', Date.now() - dt, 'ms'
	console.log '---- data: ', data
	ctx.send 'data received'

app.listen 3000