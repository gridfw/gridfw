###*
 * Build mutlipe http methods on a route
 * @example
 * 		new RouteBuilder(app, 'route')
 * 		new RouteBuilder(app, ['route1', 'route2', ...])
###
class RouteBuilder
	constructor: (app, route)->
		@_app= app
		# resolve nodes
		if typeof route is 'string'
			@_nodes= [route, _resolveTreeNode(app, route)]
		else if _isArray route
			nodes= @_nodes= []
			for el in route
				nodes.push el, _resolveTreeNode(app, el)
		else
			throw new Error 'Illegal route'
		return
	# HTTP methods
	get: (handler)-> @add 'GET', handler
	head: (handler)-> @add 'HEAD', handler
	post: (handler)-> @add 'POST', handler
	add: (methodName, handler)->
		if _isArray methodName
			for el in methodName
				@add el, handler
			return this # chain
		throw new Error "Unsupported http method: #{methodName}. Accepted are: #{HTTP_METHODS.join ', '}, ALL" unless (typeof methodName is 'string') and (((methodName= methodName.toUpperCase()) in HTTP_METHODS) or methodName is 'ALL')
		nodes= @_nodes
		len= nodes.length
		i=0
		while i<len
			route= node[i]
			node= nodes[i+1]
			i+=2
			# check controller not already set
			if (typeof node[methodName] is 'function') and (methodName isnt 'HEAD' or node.GET isnt node.HEAD)
				app.warn 'ROUTER', "Overrided controller at route: #{route}"
			# Add handler
			node[methodName]= handler
		this # chain
