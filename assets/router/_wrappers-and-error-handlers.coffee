###*
 * Wrap route
 * @example
 * 		app.wrap(handler) # Request wrapper, before routing executed
 * 		app.wrap('/', handler) # handler to all routes
 * 		app.wrap('/*', handler) # handler to wildcard route "/*"
 * 		app.wrap('/a/b')	# Handler to "/a/b" and it's subroutes
 * 		app.wrap('/a/b/')	# Handler to "/a/b/" if trailing slashes is enabled or "/a/b" and it's subroutes otherwise
 * 		app.wrap('/a/b/*')	# Handler to wildcard route: "/a/b/*"
###
wrap: (route, wrapper)->
	try
		switch arguments.length
			# Request wrapper (before Router starts)
			when 1
				wrapper= route
				throw 'Wrapper expected: async function(ctx, next){...}' unless typeof wrapper is 'function' and wrapper.length is 2
				@_wrappers.push wrapper
			# Route wrapper
			when 2
				@_wrap route, wrapper, [@_routes]
			# Illegal
			else
				throw 'Illegal arguments'
		# reload caches
		@clearRouterCache()
		this # chain
	catch err
		err= "CATCH>> #{err}" if typeof err is 'string'
		throw err
_wrap: (route, wrapper, currentNodes)->
	# flatten routes
	if _isArray route
		@wrap el, wrapper, currentNodes for el in route
		return this # chain
	throw 'Wrapper expected: async function(ctx, next){...}' unless typeof wrapper is 'function' and wrapper.length is 2
	nodes= _resolveTreeNode this, route, [@_routes]
	(node.wrappers?= []).push wrapper for node in nodes
	return
###*
 * Remove wrapper
###
unwrap: (route, wrapper)->
	switch arguments.length
		when 1
			# unwrap general handler
			if typeof route is 'function'
				_arrRemove @_wrappers, route
			# Remove all wrappers from a route node
			else
				nodes= _resolveRouteNodes this, route, [@_routes]
				for node in nodes
					node.wrappers= null
		when 2
			nodes= _resolveRouteNodes this, route, [@_routes]
			for node in nodes
				if wrappers= node.wrappers
					_arrRemove wrappers, wrapper
		else
			throw new Error 'Illegal arguments'
	# reload caches
	@clearRouterCache()
	this # chain



###*
 * Error handler
 * @example
 * 		app.catch('route', handler)
 * 		app.catch(['route'], handler)
 * 		app.catch('/', handler) # handler to all routes
 * 		app.catch('/*', handler) # handler to wildcard route "/*"
 * 		app.catch('/a/b')	# Handler to "/a/b" and it's subroutes
 * 		app.catch('/a/b/')	# Handler to "/a/b/" if trailing slashes is enabled or "/a/b" and it's subroutes otherwise
 * 		app.catch('/a/b/*')	# Handler to wildcard route: "/a/b/*"
###
catch: (route, handler)->
	try
		throw 'Illegall arguments' unless arguments.length is 2
		if _isArray route
			for el in route
				@catch el, handler
			return this # chain
		throw 'Handler expected: async function(ctx, error){...}' unless typeof handler is 'function' and handler.length is 2
		nodes= _resolveTreeNode this, route, [@_routes]
		for node in nodes
			(node.onError?= []).push handler
		# reload caches
		@clearRouterCache()
		this # chain
	catch err
		err= "CATCH>> #{err}" if typeof err is 'string'
		throw err
