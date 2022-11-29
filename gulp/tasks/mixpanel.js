var gulp_if = require("gulp-if");
var uglify = require("gulp-uglify");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  gulp.task('mixpanel', function() {
    return gulp.src(config.paths.mixpanel.src)
      .pipe(gulp.dest(config.paths.mixpanel.dest))
      .pipe(livereload());
  });

};
