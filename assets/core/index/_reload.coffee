###
Enable
disable
reload
###

# enable app
_enableApp = (app) ->
	# waiting for app to starts
	unless app[IS_LOADED] and not app[APP_STARTING_PROMISE]
		await app.reload()
	# listen into server
	app.server.on 'request', app[REQ_HANDLER] = app.handle.bind app
	# clear enabling flag
	app[APP_ENABLING_PROMISE] = null
	# return
	return

_defineProperties GridFW.prototype,
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
		await @[APP_ENABLING_PROMISE] ?= _enableApp this
		return
	###*
	 * Disable app
	 * @async
	###
	disable: value: ->
		return unless @[IS_ENABLED]
		# remove listener
		@server.off 'request', @[REQ_HANDLER] if @[REQ_HANDLER]
		# return
		return
	###*
	 * reload app
	 * @async
	 * @optional @param  {object} options - new options
	###
	reload: value: (options)->
		reloadPromise = @[APP_STARTING_PROMISE]
		reloadPrevOptions = @[APP_OPTIONS]
		@[APP_OPTIONS] = options # flag for next "reload"
		if reloadPromise
			if options and options isnt reloadPrevOptions
				# reload app again when previous reload finished
				reloadPromise = reloadPromise.finally =>
					_reloadApp this, options
		else
			reloadPromise = _reloadApp this, options || reloadPrevOptions
		# clear flags when finished
		unless reloadPromise is @[APP_STARTING_PROMISE]
			reloadPromise = reloadPromise
				.then =>
					@[IS_LOADED] = true
				.finally =>
					@[APP_STARTING_PROMISE] = null
			# save promise for next call
			@[APP_STARTING_PROMISE] = reloadPromise
		# return promise
		reloadPromise

### Reload app###
_reloadApp = (app, options)->
	app.info 'CORE', "Reload app: #{app.name}" if app[IS_LOADED]
	appSettings = app.s
	# reload settings
	options= await _reloadSettings app, options
	# Set info settings
	_defineReconfigurableProperties app,
		isProd: appSettings[<%= isProd %>]
		name: appSettings[<%= settings.name %>]
		author: appSettings[<%= settings.author %>]
		email: appSettings[<%= settings.email %>]
		baseURL: appSettings[<%= settings.baseURL %>]
	# locals
	_defineReconfigurableProperties app.locals,
		isProd: appSettings[<%= isProd %>]
		baseURL: appSettings[<%= settings.baseURL %>]

	# reload cache
	app.CACHE.clear().reload
		maxSize: appSettings[<%= settings.jsCacheMaxSize %>]
		maxStep: appSettings[<%= settings.jsCacheMaxSteps %>]
	# reload plugins
	plugins = options?.plugins
	if plugins
		throw new Error 'options.plugin expected object' unless typeof plugins is 'object'
		if appSettings[<%= settings.enableDefaultPlugins %>]
			Object.setPrototypeOf plugins, _PLUGINS
	else
		plugins = _PLUGINS
	await _reloadPlugins app, plugins
	return

### reload settings ###
_reloadSettings = (app, options)->
	# load options from file
	if (not options) or (typeof options is 'string')
		cfgPath = options or Path.join process.cwd() , CFG_FILE
		try
			# remove already existing cache
			delete require.cache[require.resolve cfgPath]
			# reload
			options = require cfgPath
			app.info 'CORE', 'Config file loaded'
		catch err
			if err? and (err.code is 'MODULE_NOT_FOUND') and err.message.indexOf(CFG_FILE) isnt -1
				if options
					throw new GError 500, 'Mising config file', err
				else
					app.warn 'CORE', "Configuration file missing at: #{options}"
					options = null
			else
				throw new GError 500, 'Config file contains errors', err
	# Init settings
	_settingsInit app, options
	return options

###*
 * Reload plugins
###
_reloadPlugins = (app, pluginsMap)->
	appPlugs= app[PLUGINS]
	plugSet = new Set Object.keys appPlugs
	promiseAll = []
	# Reload / add plugins
	for k, options of pluginsMap
		# plugin contructor
		options.require ?= k
		# reload plugin
		promiseAll.push _CreateReloadPlugin app, k, options
	# desctroy removed plugins
	if plugSet.size
		plugSet.forEach (k)->
			app.info 'PLGN', 'Destroy plugin: #{plugname}'
			promiseAll.push appPlugs[k].desctroy()
	# wait for plugins to be reloaded
	return Promise.all promiseAll

_CreateReloadPlugin = (app, plugname, settings)->
	try
		# require
		pluginConstructor = settings.require
		if typeof pluginConstructor is 'string'
			pluginConstructor = require pluginConstructor
		else unless typeof pluginConstructor is 'function'
			throw new Error "Unsupported plugin: #{plugname}"
		# debug
		app[PLUGIN_STARTING].add plugname # debug purpose
		# ingore plug case
		lowerCasePlugName = plugname.toLowerCase()
		plugs= app[PLUGINS]
		plugin= plugs[lowerCasePlugName]
		# already has a plug with this name
		if plugin
			if plugin.constructor is pluginConstructor
				return plugin.reload settings
			else
				app.warn 'PLGN', "-- Overrided plugin: #{plugname}"
				await plugin.destroy()
		else
			app.debug 'PLGN', "-- Starting plugin: #{plugname}"
		# create new plugin instance
		plugin= plugs[lowerCasePlugName]= new pluginConstructor app
		app.warn 'PLGN', "Plugin registed with different name [#{plugname}] instead of [#{pluginConstructor.name}]" unless pluginConstructor.name.toLowerCase() is lowerCasePlugName
		# check for required methods
		req = []
		for m in ['reload', 'destroy', 'enable', 'disable']
			req.push m unless m of plugin
		throw new Error "Required methods [#{req.join ','}]" if req.length
		# reload plugin
		await plugin.reload settings
		# debug
		app[PLUGIN_STARTING].delete plugname
		app.info 'PLGN', "Plugin Started: #{plugname}"
		return 
	catch err
		throw new GError 500, "Plugin load fails: #{plugname}", err
	
