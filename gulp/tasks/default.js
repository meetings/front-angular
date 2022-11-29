var runSequence = require("run-sequence");

module.exports = function (gulp, config, global){

  gulp.task('default', ['clean','version'], function(callback){
    runSequence(
      [
        'coffee',
        'sass',
        'copy',
        'img',
        'html',
        'js',
        'config',
        'tinymce',
        'mixpanel'
      ],
      callback
      );
  });

};
