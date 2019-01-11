###
Add plugins to GridFW
###
REQUIRED_PLUGIN_METHODS = ['reload']
_defineProperties GridFW.prototype,
	###*
	 * Add plugin to GridFW
	 * @optional @param  {boolean} - enable if enable the plugin @default true
	 * @param  {Plugin} plugin - GridFW plugin
	 * @example
	 * app.plugin(require('gridfw-plugin'), @optional settings)
	 * app.plugin({
	 * 		name: 'plugin name'
	 * 		reload: (app, settings)->
	 * 		disable: (app)->
	 * 		enable: (app)->
	 * }, @optional settings)
	###
	plugin: value: (plugin, settings)->
		appPlugs = @[PLUGINS]
		# get plugin
		if typeof plugin is 'string'
			throw new Error 'Illegal arguments' if arguments.length isnt 1
			name = plugin
			plugin = appPlugs[name]
			throw new Error "Unknown plugin: #{name}" unless plugin
			return plugin #return plugin wrapper
		# set new plugin
		else if typeof plugin is 'object' and plugin
			# wrap plugin
			plugin = new PluginWrapper this, plugin.name, plugin: plugin
			# override
			name = plugin.name
			# disable overrided plug if exists
			if prevPlug = appPlugs[name]
				unless prevPlug is plugin
					@info 'plugin', "Overriding plugin: #{plugin.name}"
					await prevPlug.disable() if 'disable' in prevPlug
			else
				appPlugs[name] = plugin
			# init plugin
			await plugin.reload settings
			# chain
			this
		else
			throw new Error "Illegal arguments"