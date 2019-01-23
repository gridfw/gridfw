###
Stop connections
Shutdown the process
###

_defineProperties GridFW.prototype,
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
			return

	###*
	 * Set this property to reject connections when the server's connection count gets high.
	###
	maxConnections:
		get: ->
			if @server
				@server.maxConnections
			else
				throw new Error 'Server is not set yet'
		set: (v)->
			if @server
				@server.maxConnections = v
			else
				throw new Error 'Server is not set yet'
			return


###*
 * Properly existing the process
###
_exitingProcessQeu= [] # when there is multiple servers on this process
_exitingProcess = (app, code)->
	if code
		app.warn 'CORE', "Existing app [#{app.name}] with code: #{code}"
	else if app.loaded
		app.info 'CORE', "Existing app [#{app.name}]"
	else if app[PLUGIN_STARTING].size
		app[PLUGIN_STARTING].forEach (plugName)->
			app.error 'CORE', "Plugin load fails: #{plugName}"
		app.fatalError 'CORE', 'Start fails'
	else
		app.fatalError 'CORE', 'Start fail. Did you forget to start server listening?'
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
		# pop data
		code	= _exitingProcessQeu.pop()
		app 	= _exitingProcessQeu.pop()
		# cleaning
		asyncOperations.push exitApp app, code
	# waiting for async operations
	await Promise.all asyncOperations
	# stop process if no other operation is in process
	console.log "\n\x1b[36m└──────────────────────────────────── Process Exited ─────────────────────────────────────┘\x1b[0m\n"
	process.exit()
	# process.abort()
	return
