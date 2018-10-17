path = require 'path'
###*
 * Developpement tools
###
module.exports = (app)->
	###*
	 * Show all routes in the app
	###
	app.get '/?:dev/routes', (ctx)->
		#TODO
		ctx.render path.join __direname, '../views/all-routes'