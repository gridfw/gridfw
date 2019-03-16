### add methods ###
_defineProperties GridFW.prototype,
	###*
	* add param
	* @param {String} options.name - param name
	* @param {Regex or function} options.matches - check value
	* @param {function or asyc function} options.resolver - resolve value
	* @see doc::param
	###
	param: value: (options)->
		# check options
		_checkOptions 'app.params', arguments, ['name'], ['matches', 'resolver']
		paramName = options.name
		throw new Error 'Param name expected string' unless typeof paramName is 'string'
		# prepare options
		if options.resolver or options.matches
			# matches
			matches = options.matches
			if matches
				if typeof matches is 'function'
					matches = _create null, test: value: matches
				else unless matches instanceof RegExp
					throw new Error '"matches" expected RegExp or function'
			else
				matches = EMPTY_REGEX
			# resolver
			resolver = options.resolver
			if resolver
				throw new Error "Resolver expected function" unless typeof resolver is 'function'
			else
				resolver = EMPTY_PARAM_RESOLVER
			paramV = [matches, resolver]
		else
			paramV = EMPTY_PARAM
		# save
		if @$[paramName] and @$[paramName] isnt EMPTY_PARAM
			@warn 'CORE', "Overriding Param [#{paramName}]"
		else
			@debug 'CORE', "Define param [#{paramName}]"
		@$[paramName] = paramV
		# chain
		this
	###*
	 * Error handling
	 * app.catch('/', handlerFx)
	 * app.catch(0, '/', handlerFx) # add at index 0
	###
	catch: value: (index, route, handler)->
		# check
		if typeof index is 'string'
			throw new Error 'Illegal arguments' if arguments.length isnt 2
			[index, route, handler] = [null, index, route]
		else if Number.isSafeInteger(index) and index >= 0
			throw new Error 'Illegal arguments' if arguments.length isnt 3
		else
			throw new Error 'Illegal arguments'
		# flatten routes
		# if Array.isArray route
		# 	for v in route
		# 		@catch v, handler
		# 	return
		# # check arguments
		# switch arguments.length
		# 	when 2
		# 		break
		# 	when 1
		# 		[route, handler] = ['/', route]
		# 	else
		# 		throw new Error 'Illegal arguments'
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		# adjust route (remove /*)
		route = _adjustRoute route
		# add error handler
		mapper = _createRouteTree this, route
		_wrapAt (mapper.E ?= []), index, handler
		# propagate middleware to subroutes
		_AdjustRouteMappers mapper
		# chain
		this
	###*
	 * wrap request
	 * @example
	 * // handler wrapper
	 * 		wrap(wrapperFx)		# append wrapperFx
	 * 		wrap(0, wrapperfx)	# preppend wrapperFx
	 * 		wrap(5, wrapperfx)	# add wrapperFx to this index
	 * // Controller wrapper
	 * 		wrap('/', wrapperFx)	# add this wrapper to this route
	 * 		wrap(0, '/', wrapperFx)	# preppend this wrapper to this route
	 * 		wrap(5, '/', wrapperFx)	# add this wrapper to this route at this index
	###
	wrap: value: (index, route, handler)->
		# check options
		# wrap(wrapperFx)
		if typeof index is 'function'
			[index, route, handler] = [null, null, index]
			assertArgsCount = 1
		# wrap('/', wrapperFx)
		else if typeof index is 'string'
			[index, route, handler]= [null, index, route]
			assertArgsCount= 2
		else if Number.isSafeInteger(index) and index >= 0
			# wrap(0, wrapperfx)
			if typeof route is 'function'
				[route, handler]= [null, route]
				assertArgsCount= 2
			# unless wrap(0, '/', wrapperFx)
			else unless typeof route is 'string'
				assertArgsCount= 3
				throw new Error 'Illegal arguments'
		else
			throw new Error 'Illegal arguments'
		throw new Error 'wrapper expected function' unless typeof handler
		throw new Error "Wrapper format expected: function wrapper(ctx, next){}" unless handler.length is 2
		throw new Error 'Illegal arguments count' unless arguments.length is assertArgsCount

		# wrap route
		if route
			route = _adjustRoute route
			# check handler
			mapper = _createRouteTree this, route
			_wrapAt (mapper.W ?= []), index, handler
			_AdjustRouteMappers mapper
			# clear route cache
			do @_clearRCache
		# wrap handler
		else
			_wrapAt @w, index, handler
		# chain
		this
	unwrap: (route, handler)->
		switch arguments.length
			# remove wrapper from route
			when 2
				route = _adjustRoute route
				mapper = _createRouteTree this, route, no
				if mapper
					_arrayRemove mapper.W, handler if mapper.W
					_AdjustRouteMappers mapper
					# clear route cache
					do @_clearRCache
			# remove wrapper from request handler
			when 1
				_arrayRemove @w, handler
			else
				throw new Error 'Illegal arguments'
		# chain
		this
	### clear route cache ###
	_clearRCache: value: ->
		@[CACHED_ROUTES] = _create null if @[IS_LOADED]

### wrap at ###
_wrapAt = (arr, index, wrapper)->
	if index is null
		arr.push wrapper
	else
		arr.splice index, 0, wrapper
	return

_adjustRoute= (route)->
	if route is '/*'
		route = '/'
	else if route.endsWith '/*'
		route = route.slice 0, -2
	return route