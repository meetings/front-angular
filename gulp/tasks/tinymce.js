var gulp_if = require("gulp-if");
var uglify = require("gulp-uglify");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  gulp.task('tinymce', function() {
    return gulp.src(config.paths.tinymce.src)
      .pipe(gulp.dest(config.paths.tinymce.dest))
      .pipe(livereload());
  });

};
