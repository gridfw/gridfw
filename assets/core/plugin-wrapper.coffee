###*
 * Plugin wrapper
 * settings:
 * 		require: path to required plugin
 * 		plugin: directly set plugin
###
'use strict'
#=include ../commons/_index.coffee
class PluginWrapper
	constructor: (app, name, settings)->
		# settings
		if settings
			reqPath = settings.require or name
			throw new Error "setting.require expected string" unless typeof reqPath is 'string'
			plugin = settings.plugin # optional, if directly set
		else
			reqPath = name
		# requirePath
		throw new Error "Illegal plugin name: #{name}" if name is '__proto__' or not /^[\w@$%-]+$/.test name
		app.info 'PLUGIN', "Add plugin: #{name} @ #{reqPath}"
		# require plugin
		plugin = require reqPath unless plugin
		# asserts
		app.warn 'PLUGIN', "Plugin [#{name}] registred with different name #{plugin.name}" unless name is plugin.name
		# throw new Error "Method [#{name}].init is missing" unless typeof plugin.init is 'function'
		throw new Error "Method [#{name}].reload is missing" unless typeof plugin.reload is 'function'
		# init
		# plugin.init app
		@app = app
		@plugin = plugin
		@name= name
		@path= reqPath
		return

	reload: (settings)->
		@app.debug 'PLUGIN', "Reload plugin: #{@name}"
		@plugin.reload @app, settings
	disable: ->
		p = @plugin
		if 'disable' in p
			@app.debug 'PLUGIN', "Disable plugin: #{@name}"
			await p.disable()
		return
	enable: ->
		p = @plugin
		if 'enable' in p
			@app.debug 'PLUGIN', "Enable plugin: #{@name}"
			await p.enable()
		return

module.exports = PluginWrapper