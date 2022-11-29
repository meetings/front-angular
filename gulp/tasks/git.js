var util = require("gulp-util");
var using = require("gulp-using");
var rimraf = require("gulp-rimraf");
var git = require("gulp-git");
var wait = require("gulp-wait");
var run = require("gulp-run");
var prompt = require("gulp-prompt");
var runSequence = require("run-sequence");

module.exports = function (gulp, config, global){

  gulp.task('git-clean', function() {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    return gulp.src(global.gitPath+"/*", config.paths.clean.options)
      .pipe(using({path:"cwd",prefix:"Cleaning",color:"red"}))
      .pipe(rimraf({force:true}));
  });


  gulp.task('git-copyToGit', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    util.log("Copying "+config.paths.copyToServerFolder.src+" to "+global.gitPath+"/");
    return gulp.src(config.paths.copyToServerFolder.src)
      .pipe(gulp.dest(global.gitPath+"/"));
  });

  gulp.task('git-pull', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    util.log("Fast forwarding (pulling) latest version to "+global.gitPath+" from remote repo.");
    git.pull('origin', 'master', {args: '--ff-only', cwd:global.gitPath+"/../"}, function (err) {
      if (err) throw err;
    });
    callback();
  });

  gulp.task('git-add', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    util.log("GIT adding "+global.gitPath);
    gulp.src(global.gitPath)
      .pipe(git.add({cwd:global.gitPath+"/../"}));
    callback();
  });

  gulp.task('git-confirm',['version'], function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    return gulp.src(global.gitPath)
      .pipe(wait(500))
      .pipe(run("git status",{cwd:global.gitPath}))
      .pipe(wait(500))
      .pipe(
        prompt.confirm(
          util.colors.magenta(
            "Want to continue with git commit+push for "+
            global.gitPath+" version "+global.app.version+"?"
            )
          )
        );

  });


  gulp.task('git-commit', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }

    var commitmsg = "";
    if(global.mobiledev){commitmsg = "mobiledev.meetin.gs: ";}
    if(global.mobilebeta){commitmsg = "mobilebeta.meetin.gs: ";}
    util.log("GIT committing "+global.gitPath+" version "+global.app.version);

    gulp.src(global.gitPath)
      .pipe(git.commit(commitmsg+'AUTOMATIC '+global.app.version+' release',{cwd:global.gitPath+"/../"}));
    callback();
  });

  gulp.task('git-push', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    util.log("GIT pushing "+global.gitPath+" folder");
    git.push('origin', 'master', {cwd:global.gitPath+"/../"});
    callback();
  });

  gulp.task('git-all', function (callback) {
    if(!global.gitPath){
      util.log(util.colors.red("Please do not run this task separately."));
      return;
    }
    runSequence(
      // 'test',
      ['git-pull','build'],
      'report',
      'git-clean',
      'git-copyToGit',
      'git-add',
      'git-confirm',
      'git-commit',
      'git-push',
      callback
      );
  });

};
