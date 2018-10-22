path = require 'path'
GridFW = require '../core'
###*
 * Developpement tools
###
module.exports = (app)->
	app.info 'DEV', 'Add developpement tools'
	###*
	 * Show all routes in the app
	###
	app.get '/?:dev/routes', (ctx)->
		#TODO
		# ctx.render path.join __direname, '../views/all-routes'
		# ctx.json app[GridFW.STATIC_ROUTES]
		ctx.contentType = 'json'
		ctx.send JSON.stringify app['/'], ((k, v) ->
			if typeof v is 'function'
				v = '[Function]'
			else if typeof v is 'symbol'
				v= '[Symbol]'
			v
			), "\t"