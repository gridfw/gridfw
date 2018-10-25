###
Add plugins to GridFW
###
REQUIRED_PLUGIN_METHODS = ['init', 'enable', 'disable', 'configure']
Object.defineProperties GridFW.prototype,
	###*
	 * Add plugin to GridFW
	 * @optional @param  {boolean} - enable if enable the plugin @default true
	 * @param  {Plugin} plugin - GridFW plugin
	 * @example
	 * app.plugin(require('gridfw-plugin'))
	 * app.plugin(false, require('gridfw-plugin'))
	###
	plugin: value: (enable, plugin)->
		switch arguments.length
			when 1
				[enable, plugin] = [on, enable]
			when 2
			else
				throw new Error 'Illegal arguments'
		# check
		throw new Error 'first argument expected boolean' unless typeof enable is 'boolean'
		throw new Error 'Illegal arguments' unless plugin
		# add plugin
		plugName = plugin.name
		# check it's correct GridFW plugin
		v = plugin.GridFWVersion
		throw new Error "Unsupported plugin #{plugName}" unless typeof v is 'string'
		# check plugin name
		throw new Error "Illegal plugin name: #{plugName}" unless typeof plugName is 'string' and plugName isnt '__proto__' and /^[\w@$%-]+$/.test plugName
		# check version
		if compareVersion(@version, v) is -1 # plugin needs newer version of GridFW
			throw new Error "Plugin #{plugName} needs GridFW version #{v} or newer"
		# check for required methods
		for m in REQUIRED_PLUGIN_METHODS
			throw new Error "Unsupported plugin #{plugName}, Required method: #{m}" unless typeof plugin[m] is 'function'
		# add
		@info 'PLUGIN', "Add plugin #{plugName}"
		plugs = @[PLUGINS]
		throw new Error "Plugin #{plugName} already set. use \"app.plugin('#{plugName}').configure({...})\" to reconfigure it" if plugs[plugName]
		plugs[plugName] = plugin
		# call init
		await plugin.init this
		# enable plugin
		await plugin.enable() if enable
		# statup script
		#TODO
		# shutdown script
		#TODO
		# chain
		this