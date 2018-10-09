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
			locals = Object.create appLocals,
				ctx: value: this
			# add properties
			Object.defineProperties this,
				# locals
				locals: value: locals
				data: value: locals
				# render
				view: UNDEFINED
				# content length (use for monitoring)
				contentLength: UNDEFINED
				contentType: UNDEFINED
				encoding:
					value: '<%= app.DEFAULT_ENCODING %>'
					writable: true
			return
		# request class
		@Request: AppRequest
	# add app fields
	Object.defineProperties AppContext.prototype,
		app: value: app
		s: value: app.s
		_end: value: AppContext::end
		_write: value: AppContext::write
	Object.defineProperties AppRequest.prototype,
		app: value: app
		s: value: app.s
	# add methods to prototype
	Object.defineProperties AppContext.prototype, Object.getOwnPropertyDescriptors CONTEXT_PROTO
	Object.defineProperties AppRequest.prototype, Object.getOwnPropertyDescriptors REQUEST_PROTO

	# add to app
	Object.defineProperties app,
		Context: value: AppContext
		Request: value: AppRequest
	return