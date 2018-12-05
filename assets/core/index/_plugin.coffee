###
Add plugins to GridFW
###
REQUIRED_PLUGIN_METHODS = ['reload']
Object.defineProperties GridFW.prototype,
	###*
	 * Add plugin to GridFW
	 * @optional @param  {boolean} - enable if enable the plugin @default true
	 * @param  {Plugin} plugin - GridFW plugin
	 * @example
	 * app.plugin(require('gridfw-plugin'), @optional settings)
	 * app.plugin(false, require('gridfw-plugin'), @optional settings)
	###
	plugin: value: (enable, plugin, settings)->
		unless typeof enable is boolean
			[enable, plugin, settings] = [on, enable, plugin]
		# check
		throw new Error 'Illegal arguments' unless typeof plugin is 'object' and plugin
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
		# init plugin
		await plugin.reload this, settings
		# enable plugin
		await plugin.enable() if enable
		# statup script
		#TODO
		# shutdown script
		#TODO
		# chain
		this