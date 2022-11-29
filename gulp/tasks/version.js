var filter = require("gulp-filter");
var plumber = require("gulp-plumber");
var notify = require("gulp-notify");
var coffee = require("gulp-coffee");
var util = require("gulp-util");
var concat = require("gulp-concat");
var modify = require("gulp-modify");
var vm = require("vm");
var colors = require("colors");

function warnBox(textContent){
  var filler = Array(textContent.length+1).join("═");
  return (
      "\n"+
      " ╔═"+filler+"═╗ \n"+
      " ║ "+textContent+" ║ \n"+
      " ╚═"+filler+"═╝ \n"
    ).magenta.bold.inverse;
}

module.exports = function (gulp, config, global){

  gulp.task('version', function (callback) {
    // 1. Get configuration files
    // 2. Compile js from the coffeescript-files
    // 3. Concat config files together
    // 4. Run files as javascript
    // 5. Grab variables from the js context
    var coffeeFilter = filter(['!*','**/*.coffee']);

    // Steps 1-5.
    return gulp.src(config.paths.config.src.slice(1, config.paths.config.src.length))
            .pipe(plumber({errorHandler: notify.onError("Error: <%= error.message %>")}))
            .pipe(coffeeFilter)
            .pipe(coffee({bare: true})).on('error', util.log)
            .pipe(coffeeFilter.restore())
            .pipe(concat("variables.js"))
            .pipe(modify({
              fileModifier: function(file, code) {
                var context = {};
                try{
                  vm.runInNewContext("var window = {};"+code, context, {displayErrors:true});
                }
                catch(e){
                  console.log(warnBox("Are you sure config/environment.js is ok?"));
                  console.log("Possible script error:\n"+e);
                  throw Error("Sorry, can not continue.");
                  // console.log("\nMaybe caused by:\n"+code);
                }

                global.app.version = context.window.mtnApp.version;
                global.app.androidVersionCode = context.window.mtnApp.androidVersionCode;
                global.app.name = context.window.mtnApp.appName;
                global.app.brand = context.window.mtnApp.appBrand;
                global.app.brands = context.appBrands;
                global.app.mode = context.window.mtnApp.config.mode;
                global.app.environment = context.window.mtnApp.config.environment;
                global.app.appId = context.window.mtnApp.config.appId;
                global.app.fake_platform = context.window.mtnApp.fake_platform;
                global.app.urlScheme = context.window.mtnApp.appSetting.urlScheme;

                switch(global.app.brand){
                  case global.app.brands.CMEET:
                    global.projectPath = "app/projects/cmeet/**/*";
                    break;
                  case global.app.brands.MEETINGS:
                    global.projectPath = "app/projects/meetings/**/*";
                    break;
                  case global.app.brands.SWIPETOMEET:
                    global.projectPath = "app/projects/swipetomeet/**/*";
                    break;
                  default:
                    console.log(warnBox("ERROR! UNKNOWN APP BRAND: " + global.app.brand));
                    throw(new Error("Unknown app brand '"+global.app.brand+"'! App brand is used to detect correct project path."));
                }

                console.log("Detected from environment.js");
                console.log("  name: "+global.app.name.cyan);
                console.log("  version: "+global.app.version.cyan);
                console.log("  Android version code: "+global.app.androidVersionCode.toString().cyan);
                console.log("  mode: "+global.app.mode.cyan);
                console.log("  environment: "+global.app.environment.cyan);
                console.log("  appId: "+global.app.appId.cyan);
                if(global.app.fake_platform){
                  console.log(warnBox("WARNING, FAKING PLATFORM: " + global.app.fake_platform));
                }

                return global.app.version;
              }
            }));
  });

};
