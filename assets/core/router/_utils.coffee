### Assert valid route ###
assertRoute= (route)->
	throw new Error 'route expected string' unless typeof route is 'string'
	# prevent "?" symbol and multiple successive slashes
	throw new Error 'Sequentially slashes detected' if /\/\//.test route
	throw new Error 'Symbol "?" is only allowed to escape ":" and "*"' if /[^\/]\?|\?[^:*]/.test route
	return

### adjust controller ###
_adjustRouteControllers = (mapper)->
	for method in http.METHODS
		continue unless mapper[method]
		# original controller
		controller = mapper['_' + method]
		# add parent wrappers
		

### adjust route handlers ###





###*
 * propagate handlers to subroutes
 * - Middlewares
 * - Error handlers
 * - Wrappers
###
# _AjustRouteHandlersSequences = ['M', 'E']
_AjustRouteHandlersSequences = ['E']
_AjustRouteHandlers = (routeMapper, goSubRoutes)->
	# adjust subroutes
	if goSubRoutes isnt false
		# middlewares and error handlers
		for key in _AjustRouteHandlersSequences
			if routeMapper[key]
				k = key.toLowerCase()
				_routeTreeSeek routeMapper, (parentNode, mapper)->
					# clone parent middlewares
					m = parentNode[k].slice 0
					# add child middlewares
					m.push ml for ml in mapper[key] if mapper[key]
					# set as middleware list
					mapper[k] = m
					return
	# wrappers
	if routeMapper.W
		_routeTreeSeek routeMapper, (parentNode, mapper)->
			# clone parent middlewares
			m = parentNode.w.slice 0
			# push child wrappers (LIFO)
			ref = mapper.W
			if ref
				i = ref.length
				while i > 0
					--i
					m.push ref[i]
			# set as wrappers list
			mapper.w = m
			return
	# change controller
	_adjustRouteMapper routeMapper
	unless goSubRoutes is false
		_routeTreeSeek routeMapper, (parentNode, mapper)->
			_adjustRouteMapper mapper
	return
_adjustRouteMapper = (mapper)->
	# adjust all supported HTTP methods
	for method in HTTP_SUPPORTED_METHODS
		continue unless mapper[method]
		# get original controller
		controller = mapper['_' + method]
		# add wrappers
		if mapper.w
			ref = mapper.w
			i = ref.length - 1
			while i >= 0
				controller = ref[i] controller
				throw new Error "Illegal wrapper response! wrapper: #{ref[i]}" unless typeof controller is 'function' and controller.length is 1
				--i
		# replace with new controller
		mapper[method] = controller
		# if is static route
		ref = mapper['~' + method]
		if ref
			ref[2] = controller
		return

_routeTreeSeek = (mapper, cb)->
	next = [mapper, null]
	i = 0
	loop
		# get mapper
		mapper		= next[i]
		parentNode	= next[++i]
		++i
		# cb for this mapper, when returns false, do not continue
		# with this branche
		if parentNode
			doContinue = cb parentNode, mapper
		else
			doContinue = true
		# go through this mapper subnodes
		unless doContinue is false
			for k in Reflect.ownKeys mapper
				if typeof k is 'string' and k.startsWith '/'
					next.push mapper[k], mapper
		# break
		break if i >= next.length
	return