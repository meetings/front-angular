var run = require("gulp-run");
var util = require("gulp-util");
var runSequence = require("run-sequence");

module.exports = function (gulp, config, global){

  gulp.task('weinre-start',function(){
    run("weinre --httpPort "+config.weinrePort+" --boundHost -all-").exec();
    util.log('Weinre started at: http://localhost:'+config.weinrePort+'/client/');
  });

  gulp.task('weinre', function (callback) {
    global.livereloadEnabled = true;
    runSequence(
      [
        'default',
        'weinre-start'
      ],
      'inject',
      'start-watching',
      callback
      );
  });

};
