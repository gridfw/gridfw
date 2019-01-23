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
		return _mountHandler

# mount handler
_mountHandler = (ctx)->
	settings = @s
	# sub path
	rawPath = '/' + ctx.params['*']
	# trailing slash
	unless rawPath is '/'
		unless settings[<%= settings.trailingSlash %>]
			rawPath = rawPath.slice 0, -1 if rawPath.endsWith '/'
	# wrap context
	ctx = _create ctx,
		path:
			value: rawPath
			writable: on
			configurable: on
	# call context handling
	return _handleRequest2 this, ctx
			

	