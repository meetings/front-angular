SwipeToMeet App
=============

Meetin.gs mobile application built from scratch using Cordova, Angular.js and ReactJS conventions.

Install project dependencies

 * npm install -g gulp cordova
 * npm install
 * bower install
 * Install Editor Config plugin in your favourite editor (to automatically apply .editorconfig settings)
   See: http://editorconfig.org/

Build develoment version of application:

 * copy `config/environment.js.example` -> `config/environment.js` and uncomment appropriate settings
 * `gulp`
 * Start a server (like anvil) on the folder `build`.

Run tests:

 * `gulp test`

To override your authentication credentials, set the following in local storage:

 * __session_token  = your session token
 * __session_userId = your Meetin.gs user id

See ``lib/api-requests`` for example demo account token (and for a script to request a new token).

Updating
--------
* Update npm packages: `npm update`
* Update bower packages: `bower update`

Git branching
-------------

Project loosely follows the Git branching model described at <http://nvie.com/posts/a-successful-git-branching-model/>

Branches in a nutshell

 * master   - Current application in AppStore. Always in production ready state.
 * hotfix/  - Bug fixes that need to be applied to the AppStore version. Branches forked from master.

 * develop  - Head state of development. Integration branch where all new features are merged.
 * feature/ - New features and fixes which are peer reviewed before merging into develop.

 * release/ - Stable point of development branch. Master is updated from a release branch.

Basically: master -> develop -> feature/businessValue -> develop -> release/1.0 -> master

Master needs to be merged to develop when there are hotfixes applied directly into the AppStore release.

![Branching model from nvie.com](http://nvie.com/img/2009/12/Screen-shot-2009-12-24-at-11.32.03.png)


Review checklist
----------------

 * Feature matches DoD in Github
 * All tests pass
 * Code review
  - Errors are handled in failure callbacks
 * Feature works as expected in simulator or device
 * Pull Request merged
 * Issue closed and moved to current build in Github


Pekka's Tips
------------

 * In order to test network delays and connection problems, enable iOS Network Link Conditioner in
   iOS Settings -> Developer. To get Developer menu, open XCode -> Organizer and select "Use for development"
   for your device. You may also download Hardware IO Tools for XCode to get Network Link Conditioner for iOS Simulator.

 * If API provides eg. "title" and "title_value", you should always use the attribute which has "_value" suffix.
   Updating the attribute which does not have "_value" won't succeed.

* If installing NPM packages fails mysteriously, remove both `~/.npm` and `PROJECT/node_modules` and try again.

* If you get mysterious errors with Bower dependencies, remove `app/www/components` and run `bower update` again.

* Do NOT use `sudo` for NPM packages. Always use NVM.

* Do NOT use `sudo` for RubyGems either.

* If you ever even once install dependencies with `sudo` you are doomed to have errors with permissions some day.

* Do not use tilde in bower.json version numbers. Accidental updating of eg. AngularJS may break things.

* If you run into problems with `bower update` try removing package cache (`app/www/components` or `node_modules`).

* For displaying sanitized html content ngSanitize is included in appConfig. It sanitizes ng-bind-html by default.

* If simulator does not appear in debug or in Safari's Developer menu, kill it manually from command line or reboot.

* Push notifications require a real device. They do not work in Simulator.

* Prefix custom directive names to prevent future problems. Eg `mtn-spinner` instead of `spinner`.

* Remove every "console.log" before merging your commits into develop.
  Use $log if you really need logging:
    - $log.debug (hidden in production mode)
    - $log.info  (visible in production mode)
    - $log.warn  (will be in yellow)
    - $log.error (will be in red)

* Whenever you create a button in the navigation bar remember to add mtn-blur-on-event to every input on page to hide keyboard

Deploy
======

 * Preparations:
    - Clone the repository in a different directory than your development copy.
    - Copy `config/environment.js.example` -> `config/environment.js`
    - Read instructions inside `config/environment.js`
    - `git checkout feature/swipe2meet && git pull`
    - `touch cordova/config.xml` creates config.xml if it did not already exist

 * Re-install dependencies to get rid of old and deprecated bower and node components.
    - `rm -fr node_modules app/www/components`
    - npm update
    - bower update

 * Configure production settings:
    - Select correct environment and application mode in `config/environment.js`.

 * Merge feature/swipe2meet to master-swipetomeet
    - `git checkout master-swipetomeet`
    - `git merge feature/swipe2meet`

 * Update cordova/config.xml
    - `gulp cordova-prepare` creates new xml based on environment.js and if changes are found, reinstalls cordova plugins

 * Compile javascript
    - `gulp cordova`

 * Follow platform specific build instructions (see below)

 * Increase version number in package.json

 * Add new tag to master-swipetomeet repository
    - git tag [version]
    - git push --tags


Android
=======

Set up development environment for project
 * npm install -g cordova
 * Install latest JDK
 * Install Android studio and run start up wizard to set up dev environment
 * Install Android SDK api level 19 with sdk manager
 * Set android tools and platform-tools to path
 * Install ant with homebrew:
    - brew update
    - brew install ant


Deploy
------

 * Build Android release
    - `cordova build android --release`

 * Copy cordova/platforms/android/build/outputs/apk/android-armv7-release-unsigned.apk to a folder where you have android keystore file and zipaling tool (zipaling can be found from android sdk/tools)

 * Sign and zipalign release build:
    - `jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore meetings_play.jks android-armv7-release-unsigned.apk 'android connector'`

    - `jarsigner -verify -verbose -certs android-armv7-release-unsigned.apk`

    - `./zipalign -v 4 android-armv7-release-unsigned.apk swipetomeet.apk`

 * Go to https://play.google.com/apps/publish/

 * Select swipetomeet app

 * Go to APK -> Beta testing tab

 * Upload new APK to Beta

 * Submit updates

 * Wait for processing

iOS
===

After setting up the environment with android
```
npm install/update -g ios-sim
```

Deploy
------

 * Remember to first build an Cordova version of the application to avoid the titlebar-overlaps-navbar-bug
    - 'gulp ios'

 * Open cordova/platforms/ios/SwipeToMeet.xcodeproj

 * Check xcode settings:

    - general tab:
      - Bundle Identifier should be one of these:
        - com.swipetomeet.mobile
        - gs.meetin.mobile
        - gs.meetin.cmeet.mobile
      - version should match what you're building, if you make an error and need to reupload, add fourth number to Build number that's not visible to users (ex. Version: 3.5.1 Build: 3.5.1.1)
      - deployment target 8.3 (According to Tuomas Lahti, some plugin requires this)
      - orientations:
        - iphone portrait
        - ipad all

 * Build settings tab:
    - Set `Enable bitcode` to: `No`
    - select `Provisioning Profile`
      - If there does not seem to be a proper profile, do following:
        1. Check that the profile is still active:
          1. Login to https://developer.apple.com/ Member center
          2. Open `Certificates, Identifiers & Profiles`
          3. Open `Provisioning profiles`
          4. Open `Provisioning profiles` > `All`
          5. Check proper profile, edit if needed.
        2. Check that profile is downloaded to XCode
          1. Open XCode preferences `CMD+,`
          2. Open `Accounts`-tab
          3. Select your Apple ID from the left and Meetin.gs Oy from the right.
          4. Click `Details`
          5. If Provisioning profile has a download button next to it, click it. (or Download all)

 * SwipeToMeet (or other app name)
    - Select Resources folder from left
      - Check that SwipeToMeet-Info.plist file has the following set up, without it fb link will not probably work:
```
    <key>LSApplicationQueriesSchemes</key>
    <array>
      <string>fb</string>
      <string>twitter</string>
      <string>mail</string>
      <string>skype</string>
      <string>twitter</string>
      <string>sip</string>
      <string>sips</string>
      <string>tel</string>
      <string>http</string>
      <string>https</string>
    </array>
``

 * Select product menu -> scheme -> edit scheme:
    - archive: build configuration: release

 * Product menu -> archive
    - Validate
    - Submit to App store

 * Go to itunesconnect.com

 * Select Apps -> SwipeToMeet (Or Meetin.gs or cMeet)

 * Go to prerelease tab

 * Enable TestFlight Beta Testing for the new app

 * Go to Versions tab

 * Add new version

 * Add new build to the new version and add release notes

 * Submit

 * Answer no to all questions

Wait for review

Apple watch
===========

Adding apple watch target to cordova project causes cordova-cli to stop working.
That's why apple watch app is developed in a separate xcode project in `apple_watch/` folder.
Cordova iOS project needs to be copied manually to apple_watch folder if any changes have been made to cordova app.

To get apple watch project running:

 * copy `cordova/`, `CordovaLib`, `platform_www` and `www` folders from `cordova/platforms/ios/` to `apple_watch/`

```
cp -r cordova/platforms/ios/cordova apple_watch
cp -r cordova/platforms/ios/CordovaLib apple_watch
cp -r cordova/platforms/ios/platform_www apple_watch
cp -r cordova/platforms/ios/www apple_watch
```

 * If cordova plugins have changed, copy `cordova/platforms/ios/SwipeToMeet/plugins/` to `apple_watch/SwipeToMeet/plugins`

 * Install cocoapods
    - `sudo gem install cocoapods --pre`

 * Install cocoapods dependencies by running `pod install` in `apple_watch/`

 * Open SwipeToMeet.xcworkspace in Xcode

 * Select SwipeToMeet WatchKit App scheme

 * Build and run

Apple watch app store build
---------------------------

 * Update html/js/css
   - Copy cordova/platforms/ios/www -> apple_watch/www

 * Update cordova plugins (if necessary)
   - Copy cordova/platforms/ios/SwipeTomMeet/config.xml -> apple_watch/SwipeToMeet/config.xml

   - Copy cordova/platforms/ios/SwipeTomMeet/SwipeToMeet-info.plistfo.plist -> apple_watch/SwipeToMeet/SwipeToMeet-info.plistfo.plist

   - Copy cordova/platforms/ios/SwipeTomMeet/plugins/ -> apple_watch/SwipeToMeet/plugins

   - Open SwipeToMeet.xcworkspace

   - Delete removed plugin files (marked with red text color) from project in left side panel's project navigator tab

   - Add new plugins to project by clicking right mouse button on SwipeToMeet/plugins folder and selectign Add files to SwipeToMeet...

     - Select new files, select Create groups in Added folders list, select the target in Add to targets list (Usually just SwipeToMeet)

 * Production settings in Xcode
   - SwipeToMeet WatchKit Extension and SwipeToMeet WatchKit App general settings
     - Change bundle identifier's first part to com.swipetomeet.mobile

   - SwipeToMeet WatchKit Extension/Supporting files/info.plist
     - NSExtension -> NSExtensionAttributes -> WKAppBundleIdentifier: com.swipetomeet.mobile.watckitapp

   - SwipeToMeet WatchKit App/Supporting files/info.plist
     - WKCompanionAppBundleIdentifier: com.swipetomeet.mobile

   - Check that Resources/SwipeToMeet-info.plist URL Types -> Item 0 -> URL Schemes == swipetomeet (custom url scheme)

    - Change SwipeToMeet WatchKit Extension/AppConfig.m to use production settings

    - Remember to check provisioning profiles for all three targets

Running for development:
========================

Compile javascript
```
gulp cordova
```

Build and install app to Android device/emulator
```
gulp android
```

Build and install app to iOS device
```
gulp ios-run
```

Build and install app to Android simulator
```
gulp ios
```

Single Page App (SPA) version of the code
=========================================

Same code can be used for SPA version to be run on a web server.
Some of the features (calendar sync, connectivity, etc.) are of course disabled in web version.

Gulp is used to build the SPA version while Cordova is used to build the "native" version.
Both of these can be run side by side as SPA is built into `build` folder and Cordova into `cordova` folder.

The `build` folder can be hosted straight from there with something like anvil.app and opened trough xip.io links in any local device.

## Basic one shot development build:
```
gulp
```

## Continuous development build:
```
gulp watch
```
The command `gulp watch` starts weinre and livereload server on the background for easier debugging and development. Once changes are made, the page or part of is reloaded automatically in all browsers. Weinre can be usually accessed from http://localhost:8081/client/ for debugging in mobile browsers.

## One shot deployment build:
```
gulp build
```
Only the deploymend build minimizes javascript and therefore is a bit slower. HTML is minimized on all builds. Images are not minimized as all source images under www should always be minimized before committing them and unneeded minimizing of images is painfully slow.

Styleguide
==========

The current approach to develop Styleguide means building a separate version of it with gulp.

Gulp creates a `dist` folder under `styleguide`.
It should be hosted somehow, eg. `python -m SimpleHTTPServer 8888` or http://anvilformac.com/


Setup
-----

* First, install gulp globally:
  ```npm install -g gulp```

* Install dependencies:
  ```cd styleguide```
  ```npm install```


Run
---
* Start Gulp and a local webserver
  `./styleguide.sh`

* Open Styleguide at `http://localhost:8888`

NOTE: Please open Styleguide with iOS Safari in order to have a similar environment with the application.


Run manually
------------
* Watch changes with Gulp
  `cd styleguide && gulp watch`

* Serve styleguide/dist with a webserver
  `cd styleguide/dist && python -m SimpleHTTPServer 8888`

* Open Styleguide at `http://localhost:8888`


Styleguide tips
---------------

It is preferred to use iOS Safari in order to have a similar environment with the application.

You can simulate iPhone and other touch devices with chrome by enabling emulation in
`Settings > Overrides > Show 'Emulation' view in console drawer` and opening the console drawer with `ESC`.
Just choose `Apple iPhone 5` and press `Emulate`

Here's a good tutorial to Gulpjs:
http://markgoodyear.com/2014/01/getting-started-with-gulp/

You can run the Cordova at the same time. Gulp uses same sourcecodes to generate its data.

Sourcemaps support is helpful in CSS debugging, so compass version >= 1.0.0.alpha.16 (12/05/2013) is recommended.

Check version:
```compass version```

Upgrade compass:
```gem install compass --pre```

Restarting gulp should now generate an `application.css.map` file to `styleguide/dist/stylesheets/`.

Check from chrome settings that your CSS source maps support is enabled and that you see `.scss` files instead of
`.css` files in inspector.


Running with local server
=========================

1. Check the data-node-api repository for install and running instructions.
2. Install and run it
3. Set `baseUrl: "http://0.0.0.0:8000/v1"` in app/src/config/appEnvironments.coffee
4. ???
5. Profit!
