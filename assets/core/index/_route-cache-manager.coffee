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
			currentCeil = accessCeil[level]
			app.debug 'ROUTE-CACHE', "Set cache cleaner params to level: #{level}, interval: #{currentInterval}s, ceil: #{currentCeil}"
			# convert to ms
			currentInterval *= 1000
		do _init
		# stop already existing interval
		clearInterval app[ROUTE_CACHE_INTERVAL] if app[ROUTE_CACHE_INTERVAL]
		# clean cache
		_clean = ->
			app.debug 'ROUTE-CACHE', 'Clean cache'
			# make removes
			cache = app[CACHED_ROUTES]
			keys = Object.keys cache
			# starting cleaning cache when exceeds min_count
			if keys.length > min_count
				for k, v of cache
					if (v[0] -= currentCeil) <= 0
						delete cache[k]
			# check route counts
			c = Object.keys(cache)
			if c > stepMax
				l = maxLevel
			else
				for step, i in countSteps
					if c < step
						l = i
						break
			unless level is l
				level = l
				do _init
				clearInterval app[ROUTE_CACHE_INTERVAL]
				app[ROUTE_CACHE_INTERVAL] = setInterval _clean, currentInterval

		# interval
		app[ROUTE_CACHE_INTERVAL] = setInterval _clean, currentInterval
		return