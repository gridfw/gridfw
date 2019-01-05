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
	(app, route, doCreate)->
		currentNode = app['/'] #[DYNAMIC_ROUTES]
		unless route is '/'
			# check param names are not duplicated
			paramSet.clear()
			# exec
			for part in route.split /(?=\/)/
				# create node
				node = currentNode[part] ?= _create null
				# if create node
				unless node
					if doCreate is false
						currentNode = null
						break
					else
						node = currentNode[part] = _create null
				# if param
				if part.startsWith '/?'
					isWildcard = part.charAt(2) is '*'
					throw new Error 'Illegal use of "?"' unless isWildcard or part.charAt(2) is ':'
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
						paramList = currentNode.c ?= []
						regexList = currentNode.C ?= []
					else
						paramList = currentNode.p ?= []
						regexList = currentNode.P ?= []
					paramList.push paramName
					# regex
					regex = app.$[paramName]
					if regex
						regex = regex[0]
					else
						# create empty as param
						app.$[paramName] = EMPTY_PARAM
						regex = EMPTY_REGEX
						app.warn 'RTER', "Param [#{paramName}] is undefined"
					# check no other param has the some
					if regex is EMPTY_REGEX
						for v, k in regexList
							throw new Error "[#{paramList[k]}] equals [#{v}]" if v is EMPTY_REGEX
					regexList.push regex
				# create node and go next
				currentNode = node
		# return
		currentNode