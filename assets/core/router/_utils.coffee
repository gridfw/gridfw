### Assert valid route ###
assertRoute= (route)->
	throw new Error 'route expected string' unless typeof route is 'string'
	# prevent "?" symbol and multiple successive slashes
	throw new Error 'Sequentially slashes detected' if /\/\//.test route
	throw new Error 'Symbol "?" is only allowed to escape ":" and "*"' if /[^\/]\?|\?[^:*]/.test route
	return

###*
 * Rebuild route and subroutes
 * Rebuid wrappers
 * Rebuid error handlers
###
_AdjustRouteMappers = (mapper)->
	next= [mapper]
	nextIdx = 0
	loop
		mapper = next[nextIdx++]
		# concat errors
		mapper.e = _AdjustRouteMappersConcat mapper.ee, mapper.E
		# concat wrappers
		mapper.w = _AdjustRouteMappersConcat mapper.ww, mapper.W
		# sub wrappers
		for k in Reflect.ownKeys mapper
			if typeof k is 'string' and k.startsWith '/'
				childMapper = mapper[k]
				# inheritance
				childMapper.ee = mapper.e
				childMapper.ww = mapper.w
				# next
				next.push childMapper
		# break
		if nextIdx >= next.length
			break

_AdjustRouteMappersConcat = (arr1, arr2)->
	if arr1
		if arr2
			return arr1.concat arr2
		else
			return arr1.slice 0
	else if arr2
		return arr2.slice 0
	else
		return []
