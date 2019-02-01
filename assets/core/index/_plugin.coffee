###
Add plugins to GridFW
###
_defineProperties GridFW.prototype,
	###*
	 * Add plugin to GridFW
	 * @optional @param  {boolean} - enable if enable the plugin @default true
	 * @param  {Plugin} plugin - GridFW plugin
	 * @example
	 * app.plugin(require('gridfw-plugin'), @optional settings)
	 * app.plugin(pluginConstructor, @optional settings)
	 * app.plugin('someName', pluginConstructor, @optional settings)
	###
	plugin: value: (name, pluginConstructor, settings)->
		# check args
		switch arguments.length
			when 2
				[pluginConstructor, settings] = [name, pluginConstructor]
			when 3
				break
			when 1
				if typeof name is 'string'
					plugin = @[PLUGINS][name.toLowerCase()]
					throw new Error "Unknown plugin: #{name}" unless plugin
					return plugin
				else
					pluginConstructor = name
			else
				throw new Error "Illegal arguments"
		# require plugin
		unless typeof pluginConstructor is 'function'
			throw new Error 'Illegal plugin constructor' unless typeof pluginConstructor is 'string'
			pluginConstructor = require pluginConstructor
		name ?= pluginConstructor.name
		# settings
		if settings?
			throw new Error 'settings expected object' unless typeof settings is 'object'
			throw new Error 'Illegal require setting' if settings.require?
			settings.require = pluginConstructor
		else
			settings = {require: pluginConstructor}
		# create plugin
		return _CreateReloadPlugin this, name, settings