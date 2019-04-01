###*
 * Manage route cache
###
_routeCacheStart = do ->
	# steps, when count is less then
	countSteps= [  51,  100, 500, 2000, 5000]
	maxLevel = countSteps.length - 1
	stepMax = countSteps[maxLevel]
	# cache intervals in seconds
	intervals = [3600, 1800, 600,   60, 1]
	accessCeil= [   1,    5,  20,   50, 100]
	# params
	min_count = 50 # starts removing routes when exceeds 50
	# app
	(app)->
		level = 0
		currentInterval = currentCeil = null
		_init = ->
			currentInterval = intervals[level]
			throw new Error "Illegal interval level: #{level}" unless currentInterval
			currentCeil = accessCeil[level]
			app.debug 'ROUTE-CACHE', "Set cache cleaner params to level: #{level}, interval: #{currentInterval}s, ceil: #{currentCeil}"
			# convert to ms
			currentInterval *= 1000
		do _init
		# stop already existing interval
		clearInterval app[ROUTE_CACHE_INTERVAL] if app[ROUTE_CACHE_INTERVAL]
		# clean cache
		_clean = ->
			try
				# make removes
				cache = app[CACHED_ROUTES]
				keys = Object.keys cache
				keysLen= keys.length
				app.debug 'ROUTE-CACHE', "Clean cache: [ keys len: #{keysLen} ]"
				# starting cleaning cache when exceeds min_count
				if keysLen > min_count
					for k, v of cache
						console.log '----------- cache>> for cache'
						if (v[0] -= currentCeil) <= 0
							delete cache[k]
					keys= Object.keys cache
					keysLen= keys.length
				# check route counts
				if keysLen > stepMax
					l = maxLevel
				else
					for step, i in countSteps
						console.log '----------- cache>> for count step'
						if keysLen < step
							l = i
							break
				unless level is l
					level = l
					console.log '----------- cache>> do init'
					do _init
					clearInterval app[ROUTE_CACHE_INTERVAL]
					app[ROUTE_CACHE_INTERVAL] = setInterval _clean, currentInterval
			catch err
				app.fatalError 'Route-cache', err
		# interval
		app[ROUTE_CACHE_INTERVAL] = setInterval _clean, currentInterval
		return