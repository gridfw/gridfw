###*
 * resolve routes
 * @param {GridFW} app - the app
 * @param {string} method - http method
 * @param {string} route - route path
###
_resolveRoute = do ->
	# route response
	# [0]: node
	# [1]: rawParams
	resolvedRoute = []
	nextParamNodes	= [] # store condidate nodes as [node, level, paramName, paramlevel, ...]
	wildCardStack  = [] # store routes with wildcard as [node, level, paramName, paramLevel, ...]
	# 404 Error node (enable caching)
	err404Node =
		c: ->
			throw ERROR_404
	# append nodes to wildcard stack
	_addWildcard = (nodeWildCards, currentPosition, resolvedRoute)->
		for k, v of nodeWildCards
			lst = resolvedRoute.slice 0
			lst.push k
			wildCardStack.push v, currentPosition, lst
		return
	# check regexes
	_paramRegexCheck = (currentNode, method, paramStackLen)->
		node = null
		if ( routeMapper = currentNode.m ) and
		( node = routeMapper[method] or (method is 'HEAD' and routeMapper.GET) or routeMapper.ALL )
			nodeParams = node.$
			idx = 1
			while idx < paramStackLen
				# get param info
				paramName = resolvedRoute[idx]
				paramValue = resolvedRoute[++idx]
				++idx
				# check param with regex
				t = nodeParams[paramName]
				if t and not t[0].test paramValue
					node = null
					break # test fails
		node
	# resolve dynamic route
	_resolveDynamicRoute = (app, method, route, ignoreCase)->
		resolvedRoute= [1, err404Node]
		# init
		currentNode = app[DYNAMIC_ROUTES]
		wildCardStack.length = 0
		nextParamNodes.length = 0
		# 
		parts = route.split '/'
		i = 0
		paramIdx = 2
		len = parts.length
		routeNode = null # final resolved route node
		# go to param level
		_goToParamLevel = =>
			paramIdx = nextParamNodes.pop()
			pName = nextParamNodes.pop()
			i = nextParamNodes.pop()
			currentNode = nextParamNodes.pop()
			# param stack
			resolvedRoute.splice paramIdx
			resolvedRoute.push pName, parts[i]
			paramIdx = resolvedRoute.length
			# go to next element
			++i
			return
		# loop
		loop
			# seek for path
			while i < len
				part = parts[i]
				currentPosition = i
				++i
				# ignore empty parts (case of first, last and mutiple slashes)
				continue unless part
				# ignore case for static part
				staticPart = '/' + part
				staticPart = staticPart.toLowerCase() if ignoreCase is 1
				# check if static part
				node = currentNode[staticPart]
				if node
					currentNode = node
					continue
				# add params
				if currentNode.$
					for k, v of currentNode.$
						nextParamNodes.push v, currentPosition, k, paramIdx
				# add wildcard params
				if currentNode['*']
					_addWildcard currentNode['*'], currentPosition, resolvedRoute
				# go to next node
				if nextParamNodes.length
					_goToParamLevel()
				else
					currentNode = null # fail to get route
					break
			# check params with regexes if resolved
			if currentNode and routeNode = _paramRegexCheck currentNode, method, resolvedRoute.length
				break # break loop if regexes succeed
			# if last current node has wildcard
			if currentNode and currentNode['*']
				_addWildcard currentNode['*'], i, resolvedRoute
			# if regex test fails or no node resolved, check an other track
			# go to next param track
			if nextParamNodes.length
				_goToParamLevel()
			# use a wild card path
			else if wildCardStack.length
				# get longest that matches regexes
				idx = 0
				len = wildCardStack.length
				longestLevel = 0 # store longest level
				longestParamLevel = 0 # store longest level
				while idx < len
					# resolve values
					currentNode	= wildCardStack[idx]
					i			= wildCardStack[++idx]
					pStack	= wildCardStack[++idx]
					++idx
					# continue if this level less than the last resolved one
					if i <= longestLevel
						continue
					# use regex
					if currentNode and node = _paramRegexCheck currentNode, method, i
						longestLevel = i
						longestParamStack = pStack
						routeNode = node
						break # break loop if regexes succeed
				# concat last params
				if routeNode
					resolvedRoute = longestParamStack
					resolvedRoute.push parts.slice(longestLevel).join '/'
				# break loop
				break
			# 404 not found
			else
				routeNode = null
				break
		# return node
		if routeNode
			resolvedRoute[1] = routeNode
		# end
		return resolvedRoute
	# return resolver
	(app, method, route)->
		# response
		# [_cacheLRU, node, param1Name, param1Value, ...]
		# resolvedRoute
		# params
		# rawParams = resolvedRoute[1] = Object.create null
		# root node
		if route is '/'
			node = app.m[method]
			if node or ( method is 'HEAD' and (node = app.m.GET)) or (node = app.m.ALL)
				resolvedRoute = [1, node]
			else
				resolvedRoute = [1, err404Node]
		# child node
		else
			settings = app.s
			### Remove repeated slashes ###
			# route = route.replace /\/{2,}/g, '/'
			### case sensitive ###
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
			routeMapper = app[STATIC_ROUTES][staticRoute]
			### when not static route, look for dynamic one ###
			if routeMapper and (node = routeMapper[method] or (method is 'HEAD' and (node = routeMapper.GET)) or (node=routeMapper.ALL) )
				resolvedRoute = [1, node]
			# cache logic
			else if (node = app[CACHED_ROUTES][route])
				++node[0] # inc access count (to remove less access)
				resolvedRoute = node # node
			# resolve dynamic route
			else
				resolvedRoute = _resolveDynamicRoute app, method, route, ignoreCase
				# add route to cache
				app[CACHED_ROUTES][route] = resolvedRoute
		# return resolved route
		# [_cacheLRU, node, param1Name, param1Value, ...]
		resolvedRoute
