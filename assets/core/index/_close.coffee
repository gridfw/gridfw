###
Stop connections
Shutdown the process
###

Object.defineProperties GridFW.prototype,
	###*
	 * Stop the server
	 * wait for existing connections to be finished
	###
	close: value: ->
		new Promise (resolve, reject)=>
			server = @server
			if server
				server.close (err)->
					if err
						reject err
					else resolve()
			else
				resolve()

	###*
	 * Set this property to reject connections when the server's connection count gets high.
	###
	maxConnections:
		get: ->
			throw new Error 'Server is not set yet'
			@server?.maxConnections
		set: (v)->
			throw new Error 'Server is not set yet'
			@server.maxConnections = v
			return


###*
 * Properly existing the process
###
_exitingProcessQeu= [] # when there is multiple servers on this process
_exitingProcess = (app, code)->
	app.info 'CORE', "Existing process [#{app.name}]: #{code}"
	_exitingProcessQeu.push app, code
	if _exitingProcessQeu.length is 2
		_doExit()
	return
_doExit = ->
	# exit each app
	exitApp = (app)->
		# remove listener to exit code
		process.off 'beforeExit', app._exitCb
		# do cleaning
		app.info 'CORE', "Existing process. Code: #{code}"
		# stop the server
		# waiting for all conenctions to be closed
		# await app.close().catch (err)->
		# 	console.log '---- server eerrrrror'
		# 	app.fatalError 'CORE', err
		# console.log '----- exit app server'
		# other operations
		# ....
	# async operations
	asyncOperations = []
	# do exit
	loop
		break unless _exitingProcessQeu.length
		console.log '------'
		# pop data
		code	= _exitingProcessQeu.pop()
		app 	= _exitingProcessQeu.pop()
		# cleaning
		asyncOperations.push exitApp app, code
	# waiting for async operations
	await Promise.all asyncOperations
	# stop process if no other operation is in process
	console.log '----- process exit'
	process.exit()
	# process.abort()
	return
