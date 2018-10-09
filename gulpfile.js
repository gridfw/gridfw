const gulp = require('gulp');
const gutil = require('gulp-util');
const include = require("gulp-include");
const coffeescript = require('gulp-coffeescript');
const PluginError = gulp.PluginError;
const chug = require('gulp-chug');

/* compile gulp-file.coffee */
compileRunGulp= function(){
	return gulp.src('gulp-file.coffee')
		.pipe(coffeescript({bare: true}))
		.pipe(chug())
		.on('error', gutil.log)
};

// default task
gulp.task('default', compileRunGulp);