###*
 * resolve routes
 * @param {GridFW} app - the app
 * @param {string} method - http method
 * @param {string} route - route path
###
_resolveRoute = do ->
	# store wildcard nodes
	wildcardNodes = []
	# 404 Error node (enable caching)
	err404Node =
		c: ->
			throw ERROR_404
	# resolve dynamic route
	_resolveDynamicRoute = (app, method, route, ignoreCase)->
		resolvedRoute= [1, err404Node]
		# init
		currentNode = app['/']
		wildcardNodes.length = 0
		paramIndx = 2 # excape cacheIndex and node
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
						continue lp
			# route not found as static or parametred
			currentNode = null
			break
			# check for wildcard route
			i = wildcardNodes.length
			if i
				params = app.$
				while i > 0
					# extrat data
					level = wildcardNodes[--i]
					paramIndex = wildcardNodes[--i]
					node = wildcardNodes[--i]
					# get rest of URL
					rest = parts.slice(level).join '/'
					# check if has this method
					for param, k in node.c
						p = node['/?*' + param]
						handler = p[method] or (method is 'HEAD' and p.GET) or p.ALL
						if handler and params[param][0].test rest
							resolvedRoute.splice paramIndex
							resolvedRoute.push param, rest
							currentNode = p
							`break lp`
			# 404: page not found
			# remove all params
			resolvedRoute.splice 2
			currentNode = 
			break
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
			resolvedRoute = [1, routeNode]
		# cache logic
		else if (node = app[CACHED_ROUTES][method + route])
			console.log '---- get route from cache: ', route
			++node[0] # inc access count (to remove less access)
			resolvedRoute = node # node
		# resolve dynamic route
		else
			resolvedRoute = _resolveDynamicRoute app, method, route, ignoreCase
			# add route to cache
			app[CACHED_ROUTES][method + route] = resolvedRoute
		# [_cacheLRU, node, param1Name, param1Value, ...]
		resolvedRoute