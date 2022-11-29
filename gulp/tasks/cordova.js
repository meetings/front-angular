var util = require("gulp-util");
var runSequence = require("run-sequence");
var run = require("gulp-run");
var replace = require("gulp-replace");
var rename = require("gulp-rename");
var wait = require("gulp-wait");
var fs = require('fs');
var revHash = require('rev-hash');
var gulp_if = require('gulp-if');

module.exports = function (gulp, config, global){

  //This moves the default destination path from build to somewhere else.
  function moveDestPath(pathsBranch,newPath){
    for(var i in pathsBranch){
      if(i == 'dest'||i == 'dest_dev'){
        pathsBranch[i] = pathsBranch[i].replace(/^build\//,newPath);
      }
      else if(typeof pathsBranch[i] == 'object'){
        pathsBranch[i] = moveDestPath(pathsBranch[i],newPath);
      }
    }
    return pathsBranch;
  }

  gulp.task('cordova', function (callback) {
    util.log("Building files to cordova/www/ folder with buildTarget:'native'");

    //Instead of cleaning build-folder, clean cordova folder
    config.paths.clean.src = 'cordova/www/*';

    //Instead of building to build-folder, build to cordova folder
    config.paths = moveDestPath(config.paths,'cordova/www/');
    global.environmentIsNative = true;

    runSequence(
      'default',
      callback
    );
  });

  gulp.task('androidCmd', function (callback) {
    util.log("Starting cordova build for Android, this may take some time..");
    run("cordova run android",{cwd:"cordova/"}).exec();
  });

  gulp.task('android', function (callback) {
    util.log("Building and running Android");

    runSequence(
      'cordova',
      'androidCmd',
      callback
    );
  });

  gulp.task('iosCmd', function (callback) {
    util.log("Starting cordova build for iOS, this may take some time..");
    exec("cordova run ios --target='iPhone-5s'", {cwd:"cordova/"}, puts);
  });

  gulp.task('ios', function (callback) {
    util.log("Building and running iOS simulator");

    runSequence(
      'cordova',
      'iosCmd',
      callback
    );
  });


  var sys = require('sys');
  var exec = require('child_process').exec;
  function puts(err, stdout, stderr) {
    console.log(stdout);
    console.log(stderr);
  }


  gulp.task('iosCmd-run', function (callback) {
    util.log("Starting cordova build for iOS, this may take some time..");
    exec("cordova run ios --device", {cwd:"cordova/"}, puts);
  });

  gulp.task('ios-run', function (callback) {
    util.log("Building and running iOS on the device");

    runSequence(
      'cordova',
      'iosCmd-run',
      callback
    );
  });

  gulp.task('cordova-prepare-generate', ['version'], function (callback) {

    var buffer = fs.readFileSync("cordova/config.xml");
    global.revHash = revHash(buffer);

    var name = global.app.name;
    var devmode = "OFF";
    if(global.app.mode == "development" ){
      devmode = "ON";
    }
    util.log("Preparing "+name.cyan+
      " for "+global.app.mode.cyan+" build"+
      " using version "+global.app.version.cyan +
      " in "+global.app.environment.cyan +" environment");

    var cordovaConfigTemplate  = "cordova/config.template.xml";
    var cordovaConfig  = "cordova/";

    return gulp.src(cordovaConfigTemplate)
      .pipe(replace("TEMPLATE_ID", global.app.appId))
      .pipe(replace("TEMPLATE_NAME", name))
      .pipe(replace("TEMPLATE_VERSION", global.app.version))
      .pipe(replace("TEMPLATE_ANDROIDVERSIONCODE", global.app.androidVersionCode))
      .pipe(replace("<!--TEMPLATE_START_"+global.app.name,"<!--TEMPLATE_START_"+global.app.name+" SELECTED-->"))
      .pipe(replace("TEMPLATE_END_"+global.app.name+"-->","<!--TEMPLATE_END_"+global.app.name+" SELECTED-->"))
      .pipe(replace("<!--TEMPLATE_DEVMODE_"+devmode+"_START","<!--TEMPLATE_DEVMODE_"+devmode+"_START SELECTED-->"))
      .pipe(replace("TEMPLATE_DEVMODE_"+devmode+"_END-->","<!--TEMPLATE_DEVMODE_"+devmode+"_END SELECTED-->"))
      .pipe(rename({basename:"config"}))
      .pipe(gulp.dest(cordovaConfig))
      .pipe(gulp_if(
          function(file){
            // var buffer2 = fs.readFileSync("cordova/config.xml");
            var buffer2 = file._contents;

            if(global.revHash != revHash(buffer2)){
              global.cordovaConfigRefresh = true;
              util.log("Detected change in cordova config.xml, refreshing".red);
            }else{
              util.log("No change in cordova config.xml, ignoring".green);
            }
            return global.cordovaConfigRefresh;
          },
          rename({basename:"nothing"})
        )
      );
  });


  gulp.task('cordova-prepare-refresh', function (callback) {
    var urlScheme = global.app.urlScheme;
    if(global.app.mode == "development" ){
      urlScheme = urlScheme+".dev";
    }
    if(global.cordovaConfigRefresh){
      run("cordova platform remove ios android",{cwd:"cordova/"}).exec(false,
        function(){
          run("cordova platform add ios android",{cwd:"cordova/"}).exec(false, function(){
            util.log("Rewriting featch.json custom url scheme with "+urlScheme);
            return gulp.src("cordova/plugins/fetch.json")
              .pipe(replace(/"URL_SCHEME": ".+?"/,'"URL_SCHEME": "'+urlScheme+'"'))
              .pipe(gulp.dest("cordova/plugins/"))
              .on('end',callback);
          });
        });

    }
  });


  gulp.task('cordova-prepare', ['cordova'],  function (callback) {

    runSequence(
      'cordova-prepare-generate',
      'cordova-prepare-refresh',
      callback
    );
  });


  gulp.task('native', function (callback) {
    util.log("Building and running iOS simulator & Android");

    runSequence(
      'cordova',
      'iosCmd',
      'androidCmd',
      callback
    );
  });


};
