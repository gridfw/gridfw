###*
 * Mount a sub app to this one
 * @return {function} mount handler
###
_mount = (app, subApp, method, path)->
	# check path
	throw new Error 'Mount path must ends with "/*"' unless path.endsWith '/*'
	# mounted to
	(app.mounted ?= []).push
		app: app
		path: path
		method: method
	# mounted to
	(subApp.mountedTo ?= []).push
		app: app
		path: path
		method: method
	#TODO trigger mount event
	# Log
	app.info 'CORE', "Mount app: #{subApp.name}"
	subApp.info 'CORE', "Mount to: #{app.name}"
	return subApp._mountHandler

###*
 * Unmount sub app
 * @return {function} mount handler
###
_unmount = (app, subApp, method, path)->
	#TODO
	throw new Error "unmount Inimplemented"
	# Log
	app.info 'CORE', "Unmount app: #{subApp.name}"
	subApp.info 'CORE', "Unmount from: #{app.name}"
	return subApp._mountHandler


# mount handler getter
_defineProperty GridFW.prototype, '_mountHandler',
	get: ->
		mountHandler = _mountHandler.bind this
		_defineProperty this, '_mountHandler', value: mountHandler
		return mountHandler

# mount handler
_mountHandler = (ctx)->
	settings = @s
	# Sub path
	rawPath = '/' + ctx.params['*']
	# Trailing slash
	unless rawPath is '/'
		unless settings[<%= settings.trailingSlash %>]
			rawPath = rawPath.slice 0, -1 if rawPath.endsWith '/'

	# Create context
	req = ctx.req
	ctx2 = new @Context ctx.socket
	req2 = new @Request req.socket

	# basic ctx attributes
	_defineProperties ctx2,
		req: value: req2
		res: value: ctx2
		# url
		method: value: req.method
		url:value: ctx.url
		path: # changeable by third middleware (like i18n or URL rewriter)
			value: rawPath
			writable: on
			configurable: on
		# params
		params: value: _create null
		rawQuery: value: ctx.rawQuery
		query:
			value: ctx.rawQuery
			configurable: on
		# underlying send response
		_end: value: (data, cb)-> ctx._end data, cb
		_write: value: (chunk, encoding, cb)-> ctx._write chunk, encoding, cb
	# add to request
	_defineProperties req2,
		res: value: ctx2
		ctx: value: ctx2
		req: value: req2
		headers: value: req.headers

	# wrap context
	# ctx2 = _create ctx,
		console.log '-- headers: ', req.headers
		console.log '============================='
		console.log '-- headers2: ', req2.headers
	# locals
	# locals = _create @locals,
	# 	ctx: value: ctx2
	# _defineProperties ctx2,
	# 	locals: value: locals
	# 	data: value: locals
	# call context handling
	return _handleRequest2 this, ctx2
			

	