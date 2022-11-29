module.exports = (config) ->
  config.set

    # base path, that will be used to resolve all patterns, eg. files, exclude
    basePath: '..'

    # frameworks to use
    frameworks: [
      'jasmine'
    ]

    # list of files / patterns to load in the browser
    # load your unit testable js files here
    files: [

      # Libraries
      'app/www/components/timecop/timecop-*.js', # Must be loaded before moment.js
      'app/www/components/angular/angular.min.js',
      "app/www/components/react/react-with-addons.js",
      "app/www/vendor/ngReact/ngReact.js",
      'app/www/components/angular-mocks/angular-mocks.js',
      'app/www/components/angular-sanitize/angular-sanitize.min.js',
      "app/www/components/moment/min/moment.min.js",
      "app/www/components/moment-timezone/builds/moment-timezone-with-data-2010-2020.js",
      'app/www/components/angular-route/angular-route.min.js',
      "app/www/components/angular-cache/dist/angular-cache.min.js",
      'app/www/components/lodash/lodash.min.js',
      'app/www/components/restangular/dist/restangular.min.js',
      "app/www/vendor/angular-touch.js",
      "app/www/components/angular-animate/angular-animate.min.js",
      "app/www/components/angulartics/dist/angulartics.min.js",
      "app/www/components/angulartics/dist/angulartics-segmentio.min.js",
      "app/www/vendor/TweenLite/TweenLite.js",
      "app/www/vendor/TweenLite/CSSPlugin.js",
      "app/www/vendor/jstz-1.0.4.min.js",
      "app/www/components/jquery/dist/jquery.min.js",
      "app/www/components/fastclick/lib/fastclick.js",
      "app/www/components/raven-js/dist/raven.js",
      'test/setupTestEnv.coffee',

      # Application
      'config/environment.js',
      'app/src/**/*.coffee',

      # Specs
      'test/unit/**/*Spec.coffee',
      'test/mocks/**/*.coffee'

    ]

    # list of files to exclude
    exclude: [

    ]

    plugins: [
      'karma-jasmine'
      'karma-coffee-preprocessor'
      'karma-phantomjs2-launcher'
    ]

    preprocessors:
      '**/*.coffee': ['coffee']

    # test results reporter to use
    # possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress']

    # web server port
    port: 9876

    # enable / disable colors in the output (reporters and logs)
    colors: true

    # level of logging
    # possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari (only Mac)
    # - PhantomJS
    # - IE (only Windows)
    browsers: ['PhantomJS2']

    # If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: false
