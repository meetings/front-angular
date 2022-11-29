var gulp_if = require("gulp-if");
var replace = require("gulp-replace");
var minifyHtml = require("gulp-minify-html");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  var libraryJs = '<script src="';
  libraryJs += config.paths.js.src_dev.join('"></script>\n<script src="');
  libraryJs += '"></script>\n';
  libraryJs = libraryJs.replace(/app\/\{www,null\}/g,"www");

  gulp.task('html', function() {
    return gulp.src(config.paths.html.src)
      .pipe( gulp_if( global.livereloadEnabled,
        replace( config.paths.inject.replace.from, config.paths.inject.replace.to )))
      .pipe( gulp_if( global.environmentIsNative,
        replace( config.paths.injectCordova.replace.from, config.paths.injectCordova.replace.to )))
      .pipe( gulp_if( !global.buildMode,
        replace( '<script src="app/lib.js"></script>', libraryJs )))
      .pipe( gulp_if( global.buildMode, minifyHtml( config.minifyHtmlOptions)))
      .pipe( gulp.dest( config.paths.html.dest))
      .pipe( livereload() );
  });

};
