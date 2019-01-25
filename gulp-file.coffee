gulp			= require 'gulp'
gutil			= require 'gulp-util'
fs				= require 'fs'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
rename			= require "gulp-rename"
coffeescript	= require 'gulp-coffeescript'
PluginError		= gulp.PluginError
cliTable		= require 'cli-table'
template		= require 'gulp-template' # compile some consts into digits

# compile final values (consts to be remplaced at compile time)
compileConfig= -> # gulp mast be reloaded each time this file is changed!
	gulp.src 'config/*.coffee'
	.pipe coffeescript(bare: true).on 'error', errorHandler
	.pipe gulp.dest 'config/build/'
	.on 'error', errorHandler
execConfig= ->
	require './config/build/build'
	gulp.src 'config/build/config.js'
	.pipe gulp.dest 'build/core/'
# handlers
compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
	# include related files
	.pipe include hardFail: true
	# tmp file for debuging
	.pipe gulp.dest 'tmp'
	# replace final values (compile time processing)
	.pipe template(require './config/build/settings').on 'error', errorHandler
	# convert to js
	.pipe coffeescript(bare: true).on 'error', errorHandler
	# save 
	.pipe gulp.dest 'build'
	.on 'error', errorHandler
# watch files
watch = ->
	gulp.watch ['assets/**/*.coffee'], compileCoffee
	return

# error handler
errorHandler= (err)->
	err ?= {}
	# get error line
	expr = /:(\d+):(\d+):/.exec err.stack
	code = err.code || err.source
	if expr
		line = parseInt expr[1]
		col = parseInt expr[2]
		code = code?.split("\n")[line-3 ... line + 3].join("\n")
	else
		line = col = '??'
		# save code to tmp file
		if code
			fs.writeFileSync 'tmp/err-code.tmp', code
			code = './tmp/err-code.tmp'
	# Render
	table = new cliTable()
	table.push {Name: err.name || ''},
		{plugin: err.plugin}
		{Filename: err.filename || err.fileName || '??'},
		{Message: err.message || ''},
		{Line: line || ''},
		{Col: col || ''}
	console.log """
	\x1b[0m───────────────────────────────────────────────────────────────────────────────────────────
	#{table.toString()}
	\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐
	\x1b[31mStack:
	\x1b[34m#{err.stack}
	\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘
	\x1b[31mCode:
	\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐
	\x1b[34m#{code}
	\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘
	"""
	return

# default task
gulp.task 'default', gulp.series compileConfig, execConfig, compileCoffee, watch