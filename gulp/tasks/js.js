var filter = require("gulp-filter");
var gulp_if = require("gulp-if");
var uglify = require("gulp-uglify");
var concat = require("gulp-concat");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  gulp.task('js', function() {

    var minFilter = filter(['*','!**/*.min.js']);
    var buildSrc = "src_build";
    var dest = config.paths.js.dest;
    if(!global.buildMode){
      buildSrc = "src_dev";
      dest = config.paths.js.dest_dev;
    }

    return gulp.src(config.paths.js[buildSrc])
      .pipe(gulp_if(global.buildMode, minFilter))
      .pipe(gulp_if(global.buildMode, uglify()))
      .pipe(gulp_if(global.buildMode, minFilter.restore()))
      .pipe(gulp_if(global.buildMode, concat(config.paths.js.concat)))
      .pipe(gulp.dest(dest))
      .pipe(livereload());
  });

};
