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