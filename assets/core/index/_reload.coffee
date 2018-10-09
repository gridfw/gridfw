###
Enable
disable
reload
###

Object.defineProperties GridFW.prototype,
	###*
	 * Is app enabled
	 * @return {boolean}
	###
	enabled:
		get: -> @[IS_ENABLED]
		set: (v)-> throw new Error 'Please use app.enable or app.disable instead.'
	###*
	 * Enable app
	 * @async
	###
	enable: value: ->
		return if @[IS_ENABLED]
		throw new Error 'Server not yeat set' unless @server
		# waiting for app to starts
		unless @[IS_LOADED] and not @[APP_STARTING_PROMISE]
			await @reload()
		# listen into server
		@server.on 'request', @[REQ_HANDLER] = @handle.bind this
		# return
		return
	###*
	 * Disable app
	 * @async
	###
	disable: value: ->
		return unless @[IS_ENABLED]
		# remove listener
		if @[REQ_HANDLER]
			@server.off 'request', @[REQ_HANDLER]
		# return
		return
	###*
	 * reload app
	 * @async
	 * @optional @param  {object} options - new options
	###
	reload: value: (options)->
		if @[APP_STARTING_PROMISE]
			await @[APP_STARTING_PROMISE]
		else
			@[APP_STARTING_PROMISE] = _reloadApp this, options
			.then =>
				@[APP_STARTING_PROMISE] = null
				@[IS_LOADED] = true
		return @[APP_STARTING_PROMISE]

### Reload app###
_reloadApp = (app, options)->
	app.info 'CORE', "Reload app: #{app.name}"
	appSettings = app.s
	# reload settings
	await _reloadSettings app, options
	# set logger settings
	unless Reflect.hasOwnProperty app, 'logLevel'
		Object.defineProperties app,
			logLevel:
				get: -> appSettings[<%= settings.logLevel %>]
				set: (level)->
					consoleMode = if appSettings[<%= settings.mode %>] is <%= app.DEV %> then 'dev' else 'prod'
					loggerFactory app, level: level, mode: consoleMode
					loggerFactory app.Context.prototype, level: level, mode: consoleMode
					appSettings[<%= settings.logLevel %>] = level
					return
	app.logLevel = appSettings[<%= settings.logLevel %>]
	# if use view cache
	app.debug 'CORE', 'Empty view cache'
	if appSettings[<%= settings.viewCache %>]
		if app[VIEW_CACHE]
			app[VIEW_CACHE].clear()
		else
			app[VIEW_CACHE] = new LRUCache
				max: appSettings[<%= settings.viewCacheMax %>]
	else
		app[VIEW_CACHE] = null
	# reload plugins
	await _reloadPlugins app, appSettings[<%= settings.plugins %>]
	return

### reload settings ###
_reloadSettings = (app, options)->
	# load options from file
	unless options
		try
			options = path.join process.cwd , 'gridfw-config'
			options = require options
		catch err
			app.warn 'CORE', "Could not find config file at: #{options}\n", err
			options = null
	else if typeof options is 'string'
		try
			options = require options
		catch err
			app.error 'CORE', "Could not find config file at: #{options}\n", err
			throw err
	# load default settings
	appSettings = app.s
	for v, k in CONFIG.config
		appSettings[k] = v
	configKies = CONFIG.kies
	# check and default options
	if options
		checkSettings = CONFIG.check
		# check options
		for k,v of options
			throw new Error "Illegal option: #{k}" unless checkSettings[k]
			checkSettings[k] v
			# copy to settings
			appSettings[configKies[k]] = v
	# resolve default settings based on mode
	mode = appSettings[<%= settings.mode %>]
	for k,v of CONFIG.default
		unless Reflect.hasOwnProperty options, k
			appSettings[configKies[k]] = v app, mode
	# plugins settings
	if options?.plugins
		Object.setPrototypeOf options.plugins, CONFIG.kies[<%= settings.plugins %>]
	return

###*
 * Reload plugins
###
_reloadPlugins = (app, plugSettings)->
	appPlugs= app[PLUGINS]
	plugSet = new Set Object.keys appPlugs
	promiseAll = []
	# add new plugins
	for k, v of app.s[<%= settings.plugins %>]
		if plugSet.has k
			plugSet.remove k
			unless appPlugs[k].path is v.require
				app.warn 'PLUGIN',
					"Plugin [#{k}] require path changed from [#{appPlugs[k].path}] to [#{v.require}]. Old version will be disabled only, restart app in case of problems"
				promiseAll.push appPlugs[k].disable()
				appPlugs[k] = new PluginWrapper app, k, v
		else
			appPlugs[k]= new PluginWrapper app, k, v
		promiseAll.push appPlugs[k].reload app, v
	# disable removed plugins
	if plugSet.size
		app.info 'PLUGIN', 'Disable removed plugins (Restart app to Remove theme)'
		plugSet.forEach (k)->
			promiseAll.push appPlugs[k].disable()
	# wait for plugins to be reloaded
	await Promise.all promiseAll
	return