###
Create app context
###
_createContext = (app)->
	appLocals = app.locals
	# Request
	class AppRequest extends http.IncomingMessage
		constructor: (socket)->
			super socket
	# context
	class AppContext extends http.ServerResponse
		constructor: (socket)->
			super socket
			# locals
			locals = _create appLocals,
				ctx: value: this
			# add properties
			_defineProperties this,
				# locals
				locals: value: locals
				data: value: locals
				# render
				view: UNDEFINED
				# content length (use for monitoring)
				contentLength: UNDEFINED
				contentType: UNDEFINED
				encoding:
					value: '<%= DEFAULT_ENCODING %>'
					writable: true
			return
		# request class
		@Request: AppRequest
	# add app fields
	_defineProperties AppContext.prototype,
		app: value: app
		s: value: app.s
		_end: value: AppContext::end
		_write: value: AppContext::write
	_defineProperties AppRequest.prototype,
		app: value: app
		s: value: app.s
	# add methods to prototype
	_defineProperties AppContext.prototype, Object.getOwnPropertyDescriptors CONTEXT_PROTO
	_defineProperties AppRequest.prototype, Object.getOwnPropertyDescriptors REQUEST_PROTO

	# sub app context prototype wrapper
	subAppCtxProto = _create AppContext.prototype, SUB_APP_WRAPPER.context
	subAppReqProto = _create AppRequest.prototype, SUB_APP_WRAPPER.request
	# add to app
	_defineProperties app,
		Context: value: AppContext
		Request: value: AppRequest
		# sub app wrappers
		SubAppContext: value: subAppCtxProto
		SubAppRequest: value: subAppReqProto
	return