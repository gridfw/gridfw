###*
 * resolve route
 * 
 * @route examples
 * /static/route
 * 
 * /test/*
 * /test/cc/dd/*
 * /test/cc/dd/:khalid*
 * /test/cc/dd/:filename*
 * 
 * /test/:var/:cc/mm
###
_resolveRoute = do ->
	# resolver response
	resolverResponse =
		n: null # node
		p: null # params
	# error 404 controller
	# enable caching 404 errors too
	err404Node= Object.create null,
		c: value: ->
			throw ERROR_404
	# next nodes to visite if current node fails
	nextNodes = [] # [node, paramLevel, ...]
	# store params
	resolvedParams = [] # [paramName, paramValue, ...]
	# return resolver
	(app, method, route)->
		resolverResponse.p = Object.create null
		# root node
		if route is '/'
			node = app.m[method]
			if node or ( method is 'HEAD' and (node = app.m.GET)) or (node = app.m.ALL)
				resolverResponse.n = node
			else
				resolverResponse.n = err404Node
		# child node
		else
			settings = app.s
			### case sensitive ###
			ignoreCase = settings[<%= settings.routeIgnoreCase %>]
			# ignore case: ignore static part and param values too
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
				resolverResponse.n = node

			### resolve dynamic route ###
			#TODO add cache for dynamic routes and check if it upgride performance
			

