var replace = require("gulp-replace");
var plumber = require("gulp-plumber");
var notify = require("gulp-notify");
var gulp_if = require("gulp-if");
var sourcemaps = require("gulp-sourcemaps");
var sass = require("gulp-sass");
var ignore = require("gulp-ignore");
var livereload = require("gulp-livereload");


module.exports = function (gulp, config, global){

  gulp.task('sass', function(){
    var outputStyle = "compressed";
    if(!global.buildMode){
      outputStyle = "nested";
      gulp.src(config.paths.sass.src)
        .pipe(replace(/\/\/@import "spa\/spa_imports";/g,'@import "spa/spa_imports";'))
        .pipe(gulp.dest(config.paths.sass.dest));
    }
    return gulp.src(config.paths.sass.src)
      .pipe(replace(/\/\/@import "spa\/spa_imports";/g,'@import "spa/spa_imports";'))
      .pipe(plumber({errorHandler: notify.onError("SASS Error: <%= error.message %>")}))
      .pipe(gulp_if(!global.buildMode,sourcemaps.init()))
      .pipe(sass.sync({
        errorLogToConsole:true,
        outputStyle: outputStyle
      }))
      .pipe(gulp_if(!global.buildMode,sourcemaps.write(config.paths.sass.sourcemaps_dest, {includeContent: false, sourceRoot: '/stylesheets'} )))
      .pipe(ignore(config.paths.sass.ignore))
      .pipe(gulp.dest(config.paths.sass.dest))
      .pipe(ignore("**/*.map"))
      .pipe(livereload());
  });

};
