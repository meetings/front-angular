var filter = require("gulp-filter");
var plumber = require("gulp-plumber");
var notify = require("gulp-notify");
var coffee = require("gulp-coffee");
var util = require("gulp-util");
var concat = require("gulp-concat");
var modify = require("gulp-modify");
var vm = require("gulp-vm");
var inject = require("gulp-inject");
var gulp_if = require("gulp-if");
var replace = require("gulp-replace");
var minifyHtml = require("gulp-minify-html");
var minifyInline = require("gulp-minifyInline");
var livereload = require("gulp-livereload");

module.exports = function (gulp, config, global){

  gulp.task('loginhtml', function() {
    // 1. Get configuration files
    // 2. Compile js from the coffeescript-files
    // 3. Concat config files together
    // 4. Run files as javascript
    // 5. Grab variables from the js context
    // 6. Inject variables into loginhtml
    // 7. Inject livereload if needed
    // 8. Minify html, css, js from file
    // 9. Write file to destination
    var coffeeFilter = filter(['!*','**/*.coffee']);

    // Steps 1-5.
    var vars = gulp.src(config.paths.config.src.slice(1, config.paths.config.src.length))
            .pipe(plumber({errorHandler: notify.onError("Error: <%= error.message %>")}))
            .pipe(coffeeFilter)
            .pipe(coffee({bare: true})).on('error', util.log)
            .pipe(coffeeFilter.restore())
            .pipe(concat("variables.js"))
            .pipe(modify({
              fileModifier: function(file, code) {
                var context = {};
                vm.runInNewContext("var window = {};"+code, context);
                var env = 'var appUrlScheme='+JSON.stringify(context.window.appEnvironment.signIn.appUrlScheme)+';';
                return env;
              }
            }));

    // Steps 6-9.
    return gulp.src(config.paths.loginhtml.src)
      .pipe(inject(vars, {
        starttag: '// appUrlScheme variable will be included here automatically by gulp',
        endtag: '\n',
        transform: function (filePath, file) { return file.contents.toString('utf8'); }
      }))
      .pipe(gulp_if( global.livereloadEnabled,replace( config.paths.inject.replace.from , config.paths.inject.replace.to )))
      .pipe(minifyHtml(config.minifyHtmlOptions))
      .pipe(minifyInline())
      .pipe(gulp.dest(config.paths.loginhtml.dest))
      .pipe(livereload());
  });

};
