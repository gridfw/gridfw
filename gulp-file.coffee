gulp			= require 'gulp'
gutil			= require 'gulp-util'
fs				= require 'fs'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
rename			= require "gulp-rename"
coffeescript	= require 'gulp-coffeescript'
PluginError		= gulp.PluginError

GfwCompiler		= require '../compiler'

# compile final values (consts to be remplaced at compile time)
# compileConfig= -> # gulp mast be reloaded each time this file is changed!
# 	gulp.src 'config/*.coffee'
# 	.pipe coffeescript(bare: true).on 'error', GfwCompiler.logError
# 	.pipe gulp.dest 'config/build/'
# 	.on 'error', GfwCompiler.logError
# execConfig= ->
# 	require './config/build/build'
# 	gulp.src 'config/build/config.js'
# 	.pipe gulp.dest 'build/core/'
# handlers
compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
	# include related files
	.pipe include hardFail: true
	# template
	.pipe GfwCompiler.template()
	# convert to js
	.pipe coffeescript(bare: true).on 'error', GfwCompiler.logError
	# save 
	.pipe gulp.dest 'build'
	.on 'error', GfwCompiler.logError
# watch files
watch = ->
	gulp.watch ['assets/**/*.coffee'], compileCoffee
	return

# default task
gulp.task 'default', gulp.series compileCoffee, watch
# gulp.task 'default', gulp.series compileConfig, execConfig, compileCoffee, watch