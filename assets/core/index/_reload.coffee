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
	await _reloadSettings app, options
	# set logger settings
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
	await _reloadPlugins app
	return

### reload settings ###
_reloadSettings = (app, options)->
	# load options from file
	unless options
		options = path.join process.cwd() , 'gridfw-config'
		try
			options = require options
		catch err
			if err.message.indexOf('gridfw-config') isnt -1
				app.warn 'CORE', "Configuration file missing at: #{options}"
				options = null
			else
				throw new GError 500, 'Config file contains errors', err
	else if typeof options is 'string'
		try
			options = require options
		catch err
			if err.message.indexOf('gridfw-config') isnt -1
				app.error 'CORE', "Configuration file missing at: #{options}"
				throw new GError 500, 'Mising config file', err
			else
				throw new GError 500, 'Config file contains errors', err
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
			throw new Error "Unknown option: #{k}" unless checkSettings[k]
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
		Object.setPrototypeOf options.plugins, CONFIG.config[<%= settings.plugins %>]
	return

###*
 * Reload plugins
###
_reloadPlugins = (app)->
	appPlugs= app[PLUGINS]
	plugSet = new Set Object.keys appPlugs
	promiseAll = []
	# Reload / add plugins
	for k, options of app.s[<%= settings.plugins %>]
		# plugin contructor
		pluginConstructor = require options.require || k
		# reload plugin
		promiseAll.push _CreateReloadPlugin app, k, pluginConstructor, options
	# desctroy removed plugins
	if plugSet.size
		plugSet.forEach (k)->
			app.info 'PLUGIN', 'Destroy plugin #{plugname}'
			promiseAll.push appPlugs[k].desctroy()
	# wait for plugins to be reloaded
	await Promise.all promiseAll
	return

_CreateReloadPlugin = (app, plugname, pluginConstructor, settings)->
	# ingore plug case
	lowerCasePlugName = plugname.toLowerCase()
	plugs= app[PLUGINS]
	plugin= plugs[lowerCasePlugName]
	# already has a plug with this name
	if plugin
		if plugin.constructor is pluginConstructor
			return plugin.reload settings
		else
			app.warn 'PLUGIN', "Overrided plugin #{plugname}"
			app.info 'PLUGIN', 'Destroy plugin #{plugname}'
			await plugin.destroy()
	# create new plugin instance
	plugin= plugs[lowerCasePlugName]= new pluginConstructor app
	app.warn 'PLUGIN', "Plugin registed with given name [#{plugname}] instead of original one [#{pluginConstructor.name}]" unless pluginConstructor.name.toLowerCase() is lowerCasePlugName
	# check for required methods
	req = []
	for m in ['reload', 'destroy', 'enable', 'disable']
		req.push m unless m of plugin
	throw new Error "Required methods [#{req.join ','}] on plugin: #{plugname}" if req.length
	# reload plugin
	return plugin.reload settings
