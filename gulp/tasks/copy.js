var angularTemplatecache = require("gulp-angular-templatecache");
var livereload = require("gulp-livereload");
var minifyHtml = require("gulp-minify-html");
var runSequence = require("run-sequence");

module.exports = function (gulp, config, global){

  gulp.task('copy_fonts', function(){
    return gulp.src(config.paths.copy.fonts.src)
      .pipe(gulp.dest(config.paths.copy.fonts.dest))
      .pipe(livereload());
  });
  gulp.task('copy_views', function(){
    return gulp.src(config.paths.copy.views.src)
      .pipe(minifyHtml(config.minifyHtmlOptions))
      .pipe(gulp.dest(config.paths.copy.views.dest))
      .pipe(angularTemplatecache({root:'/views/', standalone: false, module: 'appConfig'}))
      .pipe(gulp.dest(config.paths.copy.views.dest))
      .pipe(livereload());
  });
  gulp.task('copy_styleguide', function(){
    return gulp.src(config.paths.copy.styleguide.src)
      .pipe(gulp.dest(config.paths.copy.styleguide.dest))
      .pipe(livereload());
  });
  gulp.task('copy_misc', function(){
    return gulp.src(config.paths.copy.misc.src)
      .pipe(gulp.dest(config.paths.copy.misc.dest))
      .pipe(livereload());
  });
  gulp.task('copy_project', function(callback) {
    return gulp.src(global.projectPath)
      .pipe(gulp.dest(config.paths.copy.project.dest));
  });
  gulp.task('copy', function(callback) {
    runSequence(
      [
      'copy_fonts',
      'copy_views',
      'copy_styleguide',
      'copy_project',
      'copy_misc'
      ],
      callback
      );
  });

};
