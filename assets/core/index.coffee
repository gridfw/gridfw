'use strict'

http = require 'http'
Path = require 'path'
# fs	 = require 'mz/fs'
URL	 = require('url').URL
LRUCache	= require 'lru-cache'

FastDecode	= require 'fast-decode-uri-component'
Encodeurl	= require 'encodeurl'


PKG			= require '../../package.json'
CONTEXT_PROTO= require '../context'
REQUEST_PROTO= require '../context/request'
GError		= require '../lib/error'

# cache
LoggerFactory = require 'gridfw-logger'
Cache = require '../../../cache'
# Cache = require 'gridfw-cache'
ByteParser = require 'bytes'

#=include ../commons/_index.coffee
#=include _settings.coffee
#=include _default-plugins.coffee

# create empty attribute for performance
UNDEFINED=
	value: undefined
	configurable: true
	writable: true
EMPTY_OBJ = Object.freeze _create null
EMPTY_REGEX = _create null, test: value: -> true
EMPTY_FX = (value)-> value
EMPTY_PARAM_RESOLVER = (value, type, ctx)-> value
EMPTY_PARAM = [EMPTY_REGEX, EMPTY_PARAM_RESOLVER] # do not change
# void function (do not change)
# VOID_FX = ->

CFG_FILE	= 'gridfw-config'

# Routes
# ALL_ROUTES	= Symbol 'All routes'
STATIC_ROUTES	= Symbol 'Static routes'
# DYNAMIC_ROUTES	= Symbol 'Dynamic routes'
PLUGINS			= Symbol 'Plugins'
PLUGIN_STARTING	= Symbol 'Plugin starting'

# caching routes
CACHED_ROUTES		= Symbol 'Cached_routes'
ROUTE_CACHE_INTERVAL= Symbol 'Route cache interval'

# flags
IS_ENABLED				= Symbol 'is enabled'
IS_LOADED				= Symbol 'is loaded' # is app loaded (all settings are set)
APP_STARTING_PROMISE	= Symbol 'app starting promise' # loading promise
APP_ENABLING_PROMISE	= Symbol 'app enabling promise' # loading promise
REQ_HANDLER				= Symbol 'request handler'
APP_OPTIONS				= Symbol 'App starting options' # used as flag for @reload

<%
const PATH_PARAM = 0
const QUERY_PARAM = 1
%>


# default used protocol when non specified, in [http, https, http2]
DEFAULT_PROTOCOL = 'http'

# consts
HTTP_METHODS = http.METHODS
HTTP_SUPPORTED_METHODS= [
	'ALL' # all methods
	'GET'
	'HEAD'
	'POST'
	'PUT'
	'PATCH'
	'DELETE'
]

class GridFW
	###*
	 * 
	 * @param  {string} options.mode - execution mode: dev or prod
	 * @param  {number} options.routeCache - Route cache size
	 * @param  {[type]} options [description]
	 * @return {[type]}         [description]
	###
	constructor: (options)->
		# print logo
		# unless GridFW.running
		# 	GridFW.running = yes
		# 	_console_logo this
		# locals
		locals = _create null,
			app: value: this
		#TODO clone context and response
		# define properties
		_defineProperties this,
			# flags
			[REQ_HANDLER]: UNDEFINED
			[IS_ENABLED]: UNDEFINED
			[IS_LOADED]: UNDEFINED
			[APP_STARTING_PROMISE]: UNDEFINED
			[APP_ENABLING_PROMISE]: UNDEFINED
			[APP_OPTIONS]: UNDEFINED
			### App connection ###
			server: UNDEFINED
			protocol: UNDEFINED
			host: UNDEFINED
			port: UNDEFINED
			path: UNDEFINED
			ip: UNDEFINED
			ipType: UNDEFINED
			# handle request wraping
			w: value: []
			# settings
			s: value: new Array <%=settings.count %>
			sInit: _create null # settings init info
			# locals
			locals: value: locals
			data: value: locals
			# root RouteMapper
			# m: value: new RouteMapper this, '/'
			# param resolvers
			$: value: _create null,
				'*': value: EMPTY_PARAM # wildcard
			# Routes
			# [ALL_ROUTES]: value: _create null
			[STATIC_ROUTES]: value: _create null
			# [DYNAMIC_ROUTES]: value: _create null
			# route tree
			'/': value: _create null
			#TODO check if app cache optimise performance for 20 routes
			[CACHED_ROUTES]:
				value: _create null
				writable: true
			# plugins
			[PLUGINS]: value: _create null
			[PLUGIN_STARTING]: value: new Set() # debug purpose, save all starting plugins
			# mounted apps
			mounted: UNDEFINED # list of all mounted apps
			mountedTo: UNDEFINED # list of all parent apps
			# js-cache
			CACHE: value: new Cache
				# when removing item from cache
				onRemove: (key)-> delete require.cache[require.resolve key]
				# create element if not already in cache
				create: (key)-> require key
				# log
				error: (err)=> @error 'VIEW-CACHE', err
				info: (info)=> @info 'VIEW-CACHE', info
		# create context
		_createContext this
		# process off listener
		exitCb = @_exitCb = (code)=> _exitingProcess this, code
		process.on 'SIGINT', exitCb
		process.on 'SIGTERM', exitCb
		process.on 'beforeExit', exitCb
		# run load app
		@reload options
		.then =>
			# start cache cleaner
			_routeCacheStart this

		.catch (err) =>
			@fatalError 'CORE', err
			process.exit()
		return

	# <!> For debug purpose only!
	@STATIC_ROUTES: STATIC_ROUTES
# getters
_defineProperties GridFW.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening || false
	# framework version
	version: value: PKG.version
	# Errors
	errors: get: -> @s[<%=settings.errors %>]

# consts
_defineProperties GridFW,
	# param
	PATH_PARAM : value: <%= PATH_PARAM %>
	QUERY_PARAM: value: <%= QUERY_PARAM %>
	# framework version
	version: value: PKG.version
# Logger
_defineProperties GridFW.prototype,
	logLevel:
		get: -> @s[<%= settings.logLevel %>]
		set: (level)->
			consoleMode = @mode
			LoggerFactory this, level: level, mode: consoleMode
			LoggerFactory @Context.prototype, level: level, mode: consoleMode
			@s[<%= settings.logLevel %>] = level
			return
LoggerFactory GridFW.prototype, level: 'debug'
LoggerFactory CONTEXT_PROTO, level: 'debug'

#=include index/_create-context.coffee
#=include index/_log_welcome.coffee
#=include router/_index.coffee
#=include index/_handle-request.coffee
#=include index/_uncaught-request-error.coffee
#=include index/_listen.coffee
#=include index/_close.coffee
#=include index/_query-parser.coffee
#=include index/_plugin.coffee
#=include index/_reload.coffee
#=include index/_route-cache-manager.coffee
#=include index/_static-files.coffee
#=include index/_mount.coffee
#=include index/_extends.coffee

# exports
module.exports = GridFW