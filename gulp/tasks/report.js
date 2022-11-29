var util = require("gulp-util");
var eventStream = require("event-stream");
var size = require("gulp-size");

module.exports = function (gulp, config, global){

  gulp.task('report', function (callback) {
    util.log("Build done.");
    return eventStream.concat(
      gulp.src([
                'build/app/*.js',
                'build/controllers/*.js',
                'build/vendor/**/*.js',
                'build/views/*.js',
                'build/*.js',
                ]
        )
        .pipe(size({title:'All js files:',gzip:true}))
        .pipe(size({title:'All js files:',gzip:false})),
      gulp.src('build/**/*')
        .pipe(size({title:'All build files:',gzip:true}))
        .pipe(size({title:'All build files:',gzip:false}))
    );
  });

};
