var del = require("del");

module.exports = function (gulp, config, global){

  gulp.task('clean', function(callback) {
    del(config.paths.clean.src, callback);
  });

};
