###
A plugin is an object with this stricture
###

###*
 * a unique identifier of the plugin
 * @required
 * @example
 * GridFW-cookie			# 👎 could have confusion
 * com.gridfw.cookie.parser # 👍 best aproche
 * predifine cookie names
 * 		-> cookie-parser: parse cookies
###
name: "com.gridfw.cookie.parser"
###*
 * reload plugin settings
 * @required
###
reload: (app, settings)->
###*
 * Disable plugin
 * @optional
###
disable: ->
###*
 * Enable plugin
 * @optional
###
enable: ->