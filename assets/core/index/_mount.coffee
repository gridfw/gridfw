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
	try
		settings = @s
		# Sub path
		# Trailing slash
		rawPath = ctx.params['*']
		if rawPath
			rawPath = '/' + rawPath
			unless settings[<%= settings.trailingSlash %>]
				rawPath = rawPath.slice 0, -1 if rawPath.endsWith '/'
		else
			rawPath = '/'

		# Create context
		req = ctx.req
		ctx2 = _create @SubAppContext, # new @Context ctx.socket
			parentCtx: value: ctx
			# url
			method: value: ctx.method
			url: value: ctx.value
			path: # changeable by third middleware (like i18n or URL rewriter)
				value: rawPath
				writable: on
				configurable: on
			# params
			params: value: _create null
			query:
				value: ctx.rawQuery
				configurable: on 
			# underlying send response
			_end: value: ctx._end.bind ctx
			_write: value: ctx._write.bind ctx

		req2 = _create @Request.prototype, # new @Request req.socket
			parentReq: value: req
			ctx: value: ctx2
			res: value: ctx2
		# add to request
		_defineProperties req2,
			req: value: req2

		# basic ctx attributes
		_defineProperties ctx2,
			req: value: req2
			res: value: ctx2
		# call context handling
		return await _handleRequest2 this, ctx2
	catch err
		throw new GError 500, "Error in Sub app: #{@name}", err
	
			

	