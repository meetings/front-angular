var coffee = require("gulp-coffee");
var concat = require("gulp-concat");
var gulp_if = require("gulp-if");
var livereload = require("gulp-livereload");
var notify = require("gulp-notify");
var plumber = require("gulp-plumber");
var runSequence = require('run-sequence');
var uglify = require("gulp-uglify");
var util = require("gulp-util");
var wait = require("gulp-wait");

module.exports = function (gulp, config, global){

  gulp.task('coffee_common', function(){
    return gulp.src(config.paths.coffee.common.src)
      .pipe(plumber({errorHandler: notify.onError("Error: <%= error.message %>")}))
      .pipe(coffee({bare: true})).on('error', util.log)
      .pipe(concat(config.paths.coffee.common.concat))
      .pipe(gulp_if(global.buildMode, uglify({mangle:false})))
      .pipe(gulp.dest(config.paths.coffee.common.dest))
      .pipe(wait(global.coffee_delay))
      .pipe(livereload());
  });

  gulp.task('coffee_controllers', function(){
    return gulp.src(config.paths.coffee.controllers.src)
      .pipe(plumber({errorHandler: notify.onError("Error: <%= error.message %>")}))
      .pipe(coffee({bare: true})).on('error', util.log)
      .pipe(concat(config.paths.coffee.controllers.concat))
      .pipe(gulp_if(global.buildMode, uglify({mangle:false})))
      .pipe(gulp.dest(config.paths.coffee.controllers.dest))
      .pipe(wait(global.coffee_delay))
      .pipe(livereload());
  });

  gulp.task('coffee', function(callback) {
    runSequence(
      [
        'coffee_common',
        'coffee_controllers',
      ],
      callback
      );
  });

};
