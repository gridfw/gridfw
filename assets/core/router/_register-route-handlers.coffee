###*
 * Register route handlers if no controller
 * to be added to existant or future routes
 * @param {string} route - route
 * @param {obj} nodeAttrs - handlers to be added
 * @param {GridFW} app - the application
###
_registerRouteHandlers= (app, mapper, nodeAttrs)->
	throw new Error 'Controller enexpected!' if nodeAttrs.c
	#TODO
	throw new Error 'Unimplemented!'