###*
 * PARAMS
 * Method of GridFW::param
 * app.param('paramName', [regex], resolver)
 * app.param('paramName', [checkFunction], resolver)
 * @example
 * 		app.param('paramName') # Add a param without any restriction or conversion
 *
 * 		app.param('paramName', regex) # Add a param that has a specific format
 * 		app.param('paramName', function(data, ctx, TYPE){return true}) # use a function instead of regex to validate format
 *
 * 		app.param('paramName', regexOrFunction, function convert(data, ctx, TYPE){return data}) # convert parameter value using a function
 * 		app.param('paramName', regexOrFunction, async function convert(data, ctx, TYPE){return data}) # convert parameter value using an async function (load from DB, ...)
 *
 * 		TYPE in [app.PATH_PARAM, app.QUERY_PARAM]
###
param: (paramName, paramRegex, convertFx)->
	try
		# ParamName
		throw "paramName expected string" unless typeof paramName is 'string'
		throw "Illegal param name: #{paramName}" if paramName is '__proto__'
		throw "Param already set: #{paramName}" if _has @_params, paramName

		# REGEX
		if typeof paramRegex is 'function'
			paramRegex= test: paramRegex
		else unless paramRegex instanceof RegExp
			throw 'Second arg expected REGEX' if paramRegex?
			paramRegex= DEFAULT_PATH_PARAM_REGEX

		# Converter
		throw 'Third argument expected function' if convertFx? and not (typeof convertFx is 'function')

		# Add param
		@_params[paramName]= [paramRegex, convertFx]
		this # chain
	catch err
		err= "app.param>> #{err}" if typeof err is 'string'
		throw err

staticParam: (paramName, values)->
	throw new Error "ROUTER.staticParam>> Illegal argumets" unless arguments.length is 2 and typeof paramName is 'string' and _isArray values
	throw new Error "ROUTER.staticParam>> Illegal param name: #{paramName}" if paramName is '__proto__'
	throw new Error "ROUTER.staticParam>> Expected String values" for el in values when (typeof el isnt 'string') or not el
	throw new Error "ROUTER.staticParam>> Param '#{paramName}' already set" if @_params[paramName]
	@_staticParams[paramName]= values
	@_params[paramName]= [DEFAULT_PATH_PARAM_REGEX, undefined]
	this # chain
