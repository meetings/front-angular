var runSequence = require('run-sequence');
var util = require("gulp-util");

module.exports = function (gulp, config, global){

  gulp.task('build', function (callback) {
    global.buildMode = true;
    util.log("Building and optimizing for release..");
    runSequence(
      'default',
      'report',
      callback
      );
  });

  gulp.task('mobiledev', function (callback) {
    global.mobiledev = true;
    global.gitPath = config.paths.mobiledev;
    util.log("Building and optimizing for mobiledev release..");
    runSequence('git-all', callback );
  });

  gulp.task('mobilebeta', function (callback) {
    global.mobilebeta = true;
    global.gitPath = config.paths.mobilebeta;
    util.log("Building and optimizing for mobilebeta release..");
    runSequence('git-all', callback );
  });

};
