
###*
 * Route builder
###
class _RouteBuiler
	constructor: (parent, cb)->
		UNDEFINED=
			value: undefined
			configurable: true
			writable: true
			enumerable: true
		Object.defineProperties this,
			cb: value: cb
			parent: value: parent
			m: UNDEFINED # middlewares
			f: UNDEFINED # filters
			c: # controller
				value: undefined
				writable: true
			p: UNDEFINED # post process
			e: UNDEFINED # error handler
			$: value: Object.create null # param handlers
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
		cntrl = @c
		if cntrl
			# if only one controller set
			if cntrl.length is 2
				@c = cntrl[0]
			# promise like forme
			else
				@c = (ctx)->
					p = Promise.resolve ctx
					len = cntrl.length
					i=0
					while i < len
						p = p.then v[i], v[++i]
						++i
					p
		# send response to parent
		@cb this
		# return parent for chaine
		@parent
	###*
	 * add a controller
	 * @param  {function} handler
	 * @param  {function} errorHander
	 * @return {self}
	###
	then: (handler, errorHander)->
		throw new Error 'Handler expected function' if handler and typeof handler isnt 'function'
		throw new Error 'Error Handler expected function' if errorHander and typeof errorHander isnt 'function'
		# controller
		if handler
			# expect no global error handler or post handler is added
			throw new Error 'Illegal use of promise handlers, please see documentation' if @p or @e
			# add handler
			if @c
				@c.push handler, errorHander
			else
				throw new Error 'An error handler needs a controller to be added first' if errorHander
				@c = [ handler, null ]
		# cache
		else if errorHander
			if @c
				@c.push null, errorHander
			else
				( @e ?= [] ).push errorHander
		else
			throw new Error 'Illegal arguments'
		# chain
		this
	###*
	 * catch
	 * Add "Promise catch" handler or "error handling" handler
	 * @param {function} errHandler - Error handler
	 * @example
	 * .catch (error{ctx})->
	###
	catch: (errHandler)-> @then null, errHandler
	###*
	 * finally
	 * Add promise finally or post process handler
	 * @param {function} handler - Promise finally or post process handler
	 * @example
	 * .finally (ctx)->
	###
	finally: (handler)->
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		if @c
			@then handler, handler
		else
			( @p ?= [] ).push handler
		# chain
		this
	###*
	 * middlewares
	 * @example
	 * .use (ctx)->
	 * .use (ctx, res, next)-> # express compatible format, best to use it only with express middlewares
	 * .use (err, ctx, res, next)-> # express error handler compatible format, best to use it only with express middlewares
	 * .use middleware1, ... # could add multiple middlewares at once
	###
	use: (middleware)->
		# create list
		@m ?= []
		# append middlewares
		for middleware in arguments
			# sub app
			if middleware instanceof GridfW
				#TODO
				throw new Error "Sub apps are not supported by this framework version {#{@version}}. please upgrade"
				# @m.push (ctx)->
				# 	middleware.handle Object.create ctx.req, Object.create ctx
			# Gridfw format
			else unless typeof middleware is 'function'
				throw new Error 'middleware expected function'
			else if middleware.length is 1
				@m.push middleware
			# compatibility with express
			else if middleware.length is 3
				@m.push (ctx)->
					new Promise (resolve, reject)->
						middleware ctx, ctx.res, (err)->
							if err then reject err
							else resolve()
			# express error handler
			#TODO check if this error handler is compatible
			else if middleware.length is 4
				@e.push (error)->
					new Promise (resolve, reject)->
						middleware error, error.ctx, error.ctx.res, (err)->
							if err then reject err
							else resolve()
			# Uncknown format
			else
				throw new Error 'Illegal middleware format'
		# return "this" for chain
		this
	###*
	 * preHandlers
	 * @example
	 * .filter (ctx)->
	###
	filter: (handler)->
		throw new Error 'Filter expected function' unless typeof handler is 'function'
		( @f ?= [] ).push handler
		# chain
		this
	###*
	 * Param resolvers
	 * .param(name, regex)
	 * .param(name, resolver)
	 * .param(name, regex, resolver)
	###
	param: (name, regex, resolver)->
		throw new Error 'param name expected string' unless typeof name is 'string'
		throw new Error "Param name [#{name}] already set" if @$[name]
		switch arguments.length
			when 2
				if typeof regex is 'function'
					[regex, resolver] = [null, regex]
				else unless regex instanceof RegExp
					throw new Error 'regex expected RegExp'
			when 3
				throw new Error 'regex expected RegExp' unless regex instanceof RegExp
				throw new Error 'resolver expect function' unless typeof resolver is 'function'
		@$[name] = [regex, resolver]
		# chain
		this
Object.defineProperty _RouteBuiler, 'end', get: -> do @build