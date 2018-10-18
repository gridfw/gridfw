###
Create route tree
@see route-tree.txt more info and for the format
###
_createRouteTree = do ->
	# params
	ROUTE_PARAM_MATCH = /^[a-z0-9_-]+$/i
	# prevent double params
	paramSet = new Set()
	# return main function
	(app, route)->
		# fix route
		#TODO
		# if convert static parts to lower case
		convLowerCase = app.s[<%= settings.routeIgnoreCase %>]
		# check param names are not duplicated
		paramSet.clear()
		# exec
		currentNode = app[DYNAMIC_ROUTES]
		for part in route.split /(?=\/)/
			# create node
			node = node[part] ?= Object.create null
			# if param
			if part.startsWith '/?'
				isWildcard = part.chartAt(2) is '*'
				throw new Error 'Illegal use of "?"' unless isWildcard or part.chartAt(2) is ':'
				paramName = part.substr 3
				paramName = '*' unless paramName
				throw new Error 'Could not use "__proto__" as param name' if paramName is '__proto__'
				unless ( isWildcard and paramName is '*' ) or ROUTE_PARAM_MATCH.test paramName
					throw new Error "Param names mast matche [a-zA-Z0-9_-]. Illegal param: [#{paramName}] at route: #{route}"
				# uniqueness of param name
				throw new Error "Dupplicated param name: #{paramName}" if paramSet.has paramName
				paramSet.add paramName
				# add to list
				if isWildcard
					paramList = node.c ?= []
					regexList = node.C ?= []
				else
					paramList = node.p ?= []
					regexList = node.P ?= []
				paramList.push paramName
				# regex
				regex = app.$[paramName]
				if regex
					regex = regex[0]
				else
					regex = EMPTY_REGEX
					app.warn 'RTER', "Param [#{paramName}] is not defined"
				# check no other param has the some
				if regex is EMPTY_REGEX
					for v, k in regexList
						throw new Error "[#{paramList[k]}] equals [#{v}]" if v is EMPTY_REGEX
				regexList.push regex
				# add resolver
				node.r ?= Object.create null
				node.r[paramName] = app.$[paramName]?[1] || EMPTY_FX


			# static part
			else
				part = part.toLowerCase() if convLowerCase
			# create node and go next
			currentNode = node
		# return
		currentNode