###*
 * resolve routes
 * @param {GridFW} app - the app
 * @param {string} method - http method
 * @param {string} route - route path
###
_resolveRoute = do ->
	# store wildcard nodes
	wildcardNodes = []
	# staticNodeResult = [1, null, null] # for performance purpose, return this for all static routes
	# 404 Error node (enable caching)
	err404NodeHandler = ->
		throw 404
	err404Node =
		ALL: err404NodeHandler
	# resolve dynamic route
	_resolveDynamicRoute = (app, method, route, ignoreCase)->
		resolvedRoute= [1, err404Node, err404NodeHandler]
		# init
		currentNode = app['/']
		wildcardNodes.length = 0
		paramIndx = ROUTER_PARAM_STATING_INDEX # excape cacheIndex and node
		# seek for path
		parts = route.split '/'
		`lp://`
		for part, level in parts
			# ignore empty parts (case of first, last and mutiple slashes)
			continue unless part
			staticPart = '/' + part
			staticPart = staticPart.toLowerCase() if ignoreCase is 1
			# add wildcard params to queu if exists
			if currentNode.c
				wildcardNodes.push currentNode, paramIndx, level
			# check if static part
			node = currentNode[staticPart]
			if node
				currentNode = node
				continue
			# check for param
			if currentNode.P
				for regex, k in currentNode.P
					if regex.test part
						# add this param name and value to the stack
						paramName = currentNode.p[k]
						resolvedRoute.push paramName, part
						paramIndx += 2
						currentNode = currentNode['/?:' + paramName]
						`continue lp`
			# route not found as static or parametred
			currentNode = null
			break
		# Route found
		if currentNode and (handler = currentNode[method] or (method is 'HEAD' and currentNode.GET) or currentNode.ALL)
			resolvedRoute[1] = currentNode
			resolvedRoute[2] = handler
		# check for wild card route
		else
			# add current node wildcard
			if currentNode and currentNode.c
				wildcardNodes.push currentNode, paramIndx, level + 1
			# check for closest wildcard route
			if (i = wildcardNodes.length)
				params = app.$
				`wle://`
				while i > 0
					# extrat data
					level = wildcardNodes[--i]
					paramIndex = wildcardNodes[--i]
					node = wildcardNodes[--i]
					# get rest of URL
					rest = parts.slice(level).join '/'
					# check if has this method
					for param, k in node.c
						currentNode = if param is '*' then node['/?*'] else node['/?*' + param]
						handler = currentNode[method] or (method is 'HEAD' and currentNode.GET) or currentNode.ALL
						if handler and params[param][0].test rest
							resolvedRoute.splice paramIndex
							resolvedRoute.push param, rest
							resolvedRoute[1] = currentNode
							resolvedRoute[2] = handler
				# 404: page not found
				resolvedRoute.splice ROUTER_PARAM_STATING_INDEX if resolvedRoute[1] is err404Node
		# return resolved route
		resolvedRoute
	# return resolver
	(app, method, route)->
		# settings
		settings = app.s
		ignoreCase = settings[<%= settings.routeIgnoreCase %>]
		# ignore case
		if ignoreCase is 1
			route = staticRoute = route.toLowerCase()
		# ignore static part case only (do not change param values)
		else if ignoreCase is on
			staticRoute = route.toLowerCase()
		# case sensitive
		else
			staticRoute = route

		### get route if static ###
		staticRoutes = app[STATIC_ROUTES]
		routeNode = staticRoutes[method + staticRoute] or 
		method is 'HEAD' and staticRoutes['GET' + staticRoute] or 
		staticRoutes['ALL' + staticRoute]
		if routeNode
			return routeNode
		# cache logic
		else if (node = app[CACHED_ROUTES][method + route])
			++node[0] # inc access count (to remove less access)
			return node
		# resolve dynamic route
		else
			resolvedRoute = _resolveDynamicRoute app, method, route, ignoreCase
			# add route to cache
			app[CACHED_ROUTES][method + route] = resolvedRoute
			return resolvedRoute
		# [_cacheLRU, node, handler, param1Name, param1Value, ...]
		# resolvedRoute
