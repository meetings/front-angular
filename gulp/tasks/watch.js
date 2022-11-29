var replace = require("gulp-replace");
var livereload = require("gulp-livereload");
var util = require("gulp-util");
var runSequence = require("run-sequence");

module.exports = function (gulp, config, global){

  gulp.task('inject', function(){
    return gulp.src(config.paths.inject.src)
      .pipe(replace(/###inject_lr_port###/g,config.livereloadPort))
      .pipe(replace(/###inject_weinre_port###/g,global.weinre))
      .pipe(gulp.dest(config.paths.inject.dest))
      .pipe(livereload());
  });


  gulp.task('start-watching',function(callback){
    global.livereloadSilent = false;
    global.coffee_delay = config.coffee_watch_delay;

    util.log(
      "Starting to watch files. \n\n"+
      "If you get \"EMFILE too many files open\"-error, try increasing the limit with:\n"+
      "ulimit -n 4096\n"
      );

    var buildSrc = "src_build";
    if(!global.buildMode){
      buildSrc = "src_dev";
    }

    //Start livereload
    livereload.listen(config.livereloadPort);

    gulp.watch( config.paths.coffee.common.src, ['coffee_common']);
    gulp.watch( config.paths.coffee.controllers.src, ['coffee_controllers']);

    gulp.watch( config.paths.sass.src, ['sass']);

    gulp.watch( config.paths.copy.fonts.src, ['copy_fonts']);
    gulp.watch( config.paths.copy.views.src, ['copy_views']);
    gulp.watch( config.paths.copy.styleguide.src, ['copy_styleguide']);
    gulp.watch( config.paths.copy.misc.src, ['copy_misc']);

    gulp.watch( config.paths.img.src, ['img']);
    gulp.watch( config.paths.tinymce.src, ['tinymce']);
    gulp.watch( config.paths.mixpanel.src, ['mixpanel']);
    gulp.watch( config.paths.js[buildSrc], ['js']);
    gulp.watch( config.paths.config.src, ['config']);

    gulp.watch( config.paths.html.src, ['html']);

    gulp.watch( config.paths.inject.src, ['inject']);


    util.log("Okay, I'll keep an eye on things now. Happy coding!");
  });

  gulp.task('watch', function (callback) {
    global.livereloadEnabled = true;
    global.weinre='';
    runSequence(
      [
        'default'
      ],
      'inject',
      'start-watching',
      callback
      );
  });

};
