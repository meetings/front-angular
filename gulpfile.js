var gulp = require('gulp');
var config = require('./gulp/config'); // Load configuration constants

// Makes requires easier
function getTask(task){return require('./gulp/tasks/'+task)(gulp, config, global);}

// All global changing variables
var global = {
  livereloadEnabled: false,
  livereloadSilent: true,
  buildMode: false,
  weinre: config.weinrePort,
  mobiledev: false,
  mobilebeta: false,
  environmentIsNative: false,
  gitPath: false,
  app: {
    mode: "unknown",
    version: "unknown",
    environment: "unknown",
    appId: "unknown"
  },
  projectPath: null,
  coffee_delay: 0,
};

// Compiling
getTask("default"); // Builds a static development version
getTask("watch"); // Runs default and starts watch mode
getTask("weinre"); // Runs default and starts watch with weinre on
getTask("build"); // Builds a static release version, contains builds for mobiledev and mobilebeta
getTask("cordova"); // Builds a cordova version, ios, android and native commands are here
getTask("test"); // Tests the version against Karma tests

// Javascript
getTask("coffee");
getTask("js");
getTask("config"); // Creates configuration javascript from multiple files
getTask("tinymce"); // Copies tinymce-js to its place
getTask("mixpanel"); // Copies mixpanel-js to its place

// Stylesheets
getTask("sass");

// Moving files
getTask("copy"); // Copies needed files to their places
getTask("img");

// Html minification
getTask("html");
// getTask("loginhtml");

// Maintenance
getTask("clean"); // Cleans the main build folder
getTask("git");

// Reports and helpers
getTask("report");
getTask("version");
