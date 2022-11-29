Relevant gulp commands on this project
======================================

## Build commands
* `gulp` or `gulp default` - builds development version, controlled by default.js
* `gulp watch` - Runs default and starts watch mode
* `gulp weinre` - Runs default and starts watch with weinre on
* `gulp build` - Builds a static release version, contains builds for mobiledev and mobilebeta

### Mobile client commands
* `gulp cordova-prepare` - Prepares cordova xml and platforms for building. (run if gulp cordova complains about environments)
* `gulp cordova` - Builds a cordova version straight to **cordova/www/** folder
* `gulp ios` - Builds a cordova version and runs it in ios simulator
* `gulp ios-run` - Builds a cordova version and runs it in ios phone
* `gulp android` - Builds a cordova version and runs it in android simultor or phone if connected
* `gulp native` - Builds both ios and android versions.

### Autopublish commands
* `gulp mobiledev` - Builds a dev version and adds it to ../websites/mobiledev.meetin.gs/ repo.
* `gulp mobilebeta` - Builds a beta version and adds it to ../websites/mobilebeta.meetin.gs/ repo.

## Miscellanous
* `gulp test` - Tests the code against tests written with Karma
