###*
 * Plugin wrapper
###
class PluginWrapper
	constructor: (app, name, settings)->
		throw new Error "Options: plugin [#{name}] has no require directive" unless typeof settings.require is 'string'
		app.info 'PLUGIN', "Add plugin #{name} @#{settings.require}"
		# require plugin
		plugin = require settings.require
		# asserts
		app.warn 'PLUGIN', "Plugin [#{name}] registred with different name #{plugin.name}" unless name is plugin.name
		# throw new Error "Method [#{name}].init is missing" unless typeof plugin.init is 'function'
		throw new Error "Method [#{name}].reload is missing" unless typeof plugin.reload is 'function'
		# init
		# plugin.init app
		@app = app
		@plugin = plugin
		@name= name
		@path= settings.require
		return

	reload: (settings)->
		@app.debug 'PLUGIN', "Reload plugin: #{@name}"
		@plugin.reload @app, settings
	disable: ->
		p = @plugin
		app = @app
		if 'disable' in p
			app.debug 'PLUGIN', "Disable plugin: #{@name}"
			await p.disable()
		return
	enable: ->
		p = @plugin
		app = @app
		if 'enable' in p
			app.debug 'PLUGIN', "Enable plugin: #{@name}"
			await p.enable()
		return

module.exports = PluginWrapper