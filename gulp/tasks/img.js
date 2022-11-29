var gulp_if = require("gulp-if");
var imagemin = require("gulp-imagemin");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  gulp.task('img', function() {
    return gulp.src(config.paths.img.src)
      .pipe(gulp_if(global.buildMode, imagemin({
          progressive: true,
          svgoPlugins: [{removeViewBox: false}],
          use: [require('imagemin-pngcrush')()]
      })))
      .pipe(gulp.dest(config.paths.img.dest))
      .pipe(livereload());
  });

};
