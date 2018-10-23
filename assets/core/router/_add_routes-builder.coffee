
###*
 * Route builder
 * app.on('GET', 'path')
 * 		.param 'paramName', /regex/, resolver(value, ctx)
 * 		.then handler(ctx)
 * 		.then handler(ctx)
 * 		.catch errHandler(ctx)
 * 		.then handler(ctx)
 * 		.finally handler(ctx)
 * 		.then handler(ctx)
 * 		.catch errHandler(ctx)
 * 		.end
###
class _RouteBuiler
	constructor: (app, cb)->
		Object.defineProperties this,
			cb: value: cb
			app: value: app
			controller: value: []
			wrappers: value: []
			# set timeout to build
			_build: value: setImmediate => do @build
		return

	###*
	 * build handlers
	###
	build: ->
		# cancel build request
		clearImmediate @_build
		# fixe controller when promise forme
		controller = @controller
		throw new Error 'Not controller set!' unless controller.length
		# Simple controller
		if controller.length is 2
			ctrlFx = controller[0]
		# Promise controller
		else
			ctrlFx = (ctx)->
				len = controller.length
				i   = 0
				p   = Promise.resolve ctx
				while i < len
					p = p.then controller[i], controller[++i]
					++i
				p
		# send response to parent
		@cb ctrlFx, {wrappers: @wrappers}
		# return parent for chaine
		@app
	###*
	 * add a controller
	 * @param  {function} handler
	 * @param  {function} errorHander
	 * @return {self}
	###
	then: (handler, errorHander)->
		throw new Error 'Handler expected function' if handler and typeof handler isnt 'function'
		throw new Error 'Error Handler expected function' if errorHander and typeof errorHander isnt 'function'
		throw new Error 'Illegal arguments' unless handler or errorHander
		# check error handler add
		controller = @controller
		throw new Error 'Adding Error handler withoud previous controller' unless controller.length or !errorHander
		controller.push handler, errorHander
		# chain
		this
	###*
	 * catch
	###
	catch: (errHandler)-> @then null, errHandler
	###*
	 * finally
	###
	finally: (handler)-> @then handler, handler
	###*
	 * Alias to app.param
	###
	param: (name, regex, resolver)->
		@app.param.apply @app, arguments
		# chain
		this
	### wrapper ###
	wrap: (wrapper)->
		wrappers.push wrapper
		# chain
		this
Object.defineProperty _RouteBuiler.prototype, 'end', get: -> do @build