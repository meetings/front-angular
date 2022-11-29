var karma = require("gulp-karma");

module.exports = function (gulp, config, global){

  gulp.task('karma', function (callback) {
    // Testfiles configured in karma.coffee
    return gulp.src([])
      .pipe(karma({
        configFile: 'test/karma.coffee',
        action: 'watch'
      }));
  });

  gulp.task('test', function (callback) {
    // Testfiles configured in karma.coffee
    return gulp.src([])
      .pipe(karma({
        configFile: 'test/karma.coffee',
        action: 'run'
      }))
      .on('error', function(err) {
        // Make sure failed tests cause gulp to exit non-zero
        throw err;
      });
  });

};
