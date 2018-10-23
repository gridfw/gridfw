### Assert valid route ###
assetRoute= (route)->
	throw new Error 'route expected string' unless typeof route is 'string'
	# prevent "?" symbol and multiple successive slashes
	throw new Error 'Sequentially slashes detected' if /\/\//.test route
	throw new Error 'Symbol "?" is only allowed to escape ":" and "*"' if /[^\/]\?|\?[^:*]/.test route
	return

###*
 * propagate handlers to subroutes
 * - Middlewares
 * - Error handlers
 * - Wrappers
###
_AjustRouteHandlers = (routeMapper)->
	# adjust middlewares
	if routeMapper.m
		_routeTreeSeek routeMapper, (mapper, parentNode)->
			# clone parent middlewares
			m = parentNode.m.slice 0
			# add child middlewares
			m.push ml for ml in mapper.M if mapper.M
			# set as middleware list
			mapper.m = m

_routeTreeSeek = (mapper, cb)->
	next = [mapper, null]
	i = 0
	loop
		# get mapper
		mapper		= next[i]
		parentNode	= next[++i]
		++i
		continue unless parentNode
		# cb for this mapper
		cb parentNode, mapper
		# go through this mapper subnodes
		for k in Reflect.ownKeys mapper
			if typeof k is 'string' and k.startsWith '/'
				next.push mapper[k], mapper
		# break
		break unless i >= next.length
	return