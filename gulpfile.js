const gulp = require('gulp');
const gutil = require('gulp-util');
const include = require("gulp-include");
const coffeescript = require('gulp-coffeescript');
const chug = require('gulp-chug');

// get arguments with '--'
var args = []
for(var i=0, argv= process.argv, len = argv.length; i < len; ++i)
	if(argv[i].startsWith('--'))
		args.push(argv[i])
	
/* compile gulp-file.coffee */
var exitCode = 0
compileRunGulp= function(){
	return gulp.src('gulp-file.coffee')
		.pipe( coffeescript({bare: true}) )
		.pipe( chug({args: args}) )
		.on('error', function(err){
			console.error('\x1b[41mERROR At ', err.plugin, '>>', err.message, '\x1b[0m');
			exitCode = 1
		});
};

process.on('exit', function(code){
	if(exitCode) // when error
		process.exit(exitCode);
});

// default task
gulp.task('default', compileRunGulp);