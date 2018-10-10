###*
 * resolve route
 * @return [routeMapper, resolvedParams]
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
	# for performance perpose, we reuse those arrays ( hold on, js is unithread ;) )
	filteredNodes1 = [] 
	filteredNodes2 = []
	# return this array
	(app, method, route)->
		# root node
		if route is '/'
			node = app.m[method]
			unless node or ( method is 'HEAD' and (node = app.m.GET)) or (node = app.m.ALL)
				throw ERROR_404
			routeMapper = [node, null]
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
				routeMapper = [node, null]

			### resolve dynamic route ###
			#TODO add cache for dynamic routes and check if it upgride performance
			else
				# epmpty buffers
				filteredNodes2.length = 0
				filteredNodes2.push app[DYNAMIC_ROUTES], Object.create null

				for part in route.split '/'
					continue unless part # continue if part is null, case of multiple slashes
					# ignore case for static part
					staticPart = '/' + part
					staticPart = staticPart.toLowerCase() if ignoreCase is 1
					# invert arrays
					[filteredNodes1, filteredNodes2] = [filteredNodes2, filteredNodes1]
					filteredNodes2.length = 0
					# go through current step resolved nodes
					len = filteredNodes1.length
					i = 0
					while i < len
						# varibles
						node = filteredNodes1[i]
						params = filteredNodes1[++i]
						++i

						# next static node
						nextNode = node[staticPart]


