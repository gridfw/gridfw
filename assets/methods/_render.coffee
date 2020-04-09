###*
 * Render views
 * @return {String} - rendered HTML
###
render: (locale, path, data)->
	try
		# Data
		data= if data then (_assign {}, @data, data) else @data
		filePath= Path.resolve(@settings.views, locale, path)+'.js'
		# Load render fx
		renderFx= await @_viewCache.get filePath
		# render
		return renderFx data
	catch err
		if err and err.code is 'ENOENT'
			err= new GError '404-view', "View not found at: #{filePath}", new Error 'View not found'
		else
			err= new GError 500, "View error at: #{filePath}", err
		throw err
	