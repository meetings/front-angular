var coffee = require("gulp-coffee");
var concat = require("gulp-concat");
var filter = require("gulp-filter");
var gulp_if = require("gulp-if");
var livereload = require("gulp-livereload");
var notify = require("gulp-notify");
var plumber = require("gulp-plumber");
var replace = require("gulp-replace");
var uglify = require("gulp-uglify");
var util = require("gulp-util");
var wait = require("gulp-wait");
var modify = require("gulp-modify");
var vm = require("vm");

module.exports = function (gulp, config, global){

  gulp.task('config', function() {
    var envFilter = filter(['!*','**/environment.js']);
    var coffeeFilter = filter(['!*','**/*.coffee']);

    return gulp.src(config.paths.config.src)
      .pipe(plumber({errorHandler: notify.onError("Error: <%= error.message %>")}))
      .pipe(envFilter)
      .pipe(modify({
              fileModifier: function(file, code) {
                var context = {};
                try{
                  vm.runInNewContext("var window = {};"+code, context, {displayErrors:true});
                }
                catch(e){
                  console.log("Possible script error:\n"+e+"\n\nmaybe caused by:"+code);
                }
                var env = 'var mtnApp='+JSON.stringify(context.mtnApp)+';';
                env += 'mtnApp.appBrands='+JSON.stringify(context.appBrands)+';';
                return env;
              }
            }))
      .pipe(envFilter.restore())
      .pipe(coffeeFilter)
      .pipe(coffee({bare: true})).on('error', util.log)
      .pipe(coffeeFilter.restore())
      .pipe(concat(config.paths.config.concat))
      .pipe(gulp_if(global.buildMode,uglify({mangle:false})))
      .pipe(gulp.dest(config.paths.config.dest))
      .pipe(wait(global.coffee_delay))
      .pipe(livereload());
  });

};
