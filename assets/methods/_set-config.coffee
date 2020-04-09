###*
 * Set app configuration
###
setConfig: (config)->
	throw new Error 'SET-CONFIG>> Illegal arguments' unless arguments.length is 1 and typeof config is 'object'
	# Set values
	settings= @settings
	for k,v of config
		try
			v= OPTIONS_CHECK[k]?.call this, v # Check option
			settings[k]= v	# save option (could be user custom option)
		catch err
			err= new Error "options.#{k}>> #{err}" if typeof err is 'string'
			throw err
	# set new configuration
	@logLevel= settings.logLevel

	# ROUTER CACHE
	@_routerCache.setConfig
		max: settings.routerCacheMax
		ttl: settings.routerCacheTTL

	# VIEW CACHE
	@_viewCache.setConfig
		max:	settings.viewCacheMax
		ttl:	settings.viewCacheTTL
		maxBytes: settings.viewCacheMaxBytes

	# I18N CACHE
	@_i18nCache.setConfig
		max:	settings.i18nCacheMax
		ttl:	settings.i18nCacheTTL
		maxBytes: settings.i18nCacheMaxBytes

	# I18N PATHS
	@_i18nCache.clear()
	@defaultLocale= settings.defaultLocale
	if mapperPath= settings.i18nMapper
		mapperData= JSON.parse Fs.readFileSync mapperPath
		# Convert relative links to absolute
		mapperData= mapperData.locales
		mapperPath= Path.dirname mapperPath
		for k,v of mapperData
			mapperData[k]= Path.resolve mapperPath, v
		# insert
		@_i18nPaths= mapperData
		locales= @locales= _keys mapperData
		throw new Error "Default locale [#{@defaultLocale}] file is missing. Found are: #{locales.join ','}" unless @defaultLocale in locales
	this # chain