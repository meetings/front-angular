var config = {};
config.livereloadPort = 35729;
config.weinrePort = 8081;
config.coffee_watch_delay = 500;

//True = do not remove, False = remove stuff. Default is false.
config.minifyHtmlOptions = {
  empty:true, //- do not remove empty attributes
  cdata:false, //- do not strip CDATA from scripts
  comments:false, //- do not remove comments
  conditionals:false, //- do not remove conditional internet explorer comments
  spare:false, //- do not remove redundant attributes
  quotes:false, //- do not remove arbitrary quotes
};

config.paths = {
  clean: {
    src: ['build/*'],
    options: {read: false}
  },

  coffee: {
    common: {
      src: 'app/src/{react_components,directives,services,factories,filters,mixins}/**/*.coffee',
      concat: 'app.js',
      dest: 'build/app/'
    },
    controllers: {
      src: [
        'app/src/controllers/*.coffee'
      ],
      concat: 'controllers.js',
      dest: 'build/controllers/'
    }
  },

  sass: {
    src: 'app/www/**/*.scss',
    ignore: '/**/app/www/components/**/*.css',
    dest: 'build/',
    sourcemaps_dest: './sourcemaps/'
  },

  copy: {
    fonts: {
      src: [
        'app/www/**/*.{eot,ttf,woff,otf}',
        '!app/www/components/**/*'
      ],
      dest: 'build/'
    },
    views: {
      src: ['app/src/views/**/*.html','!app/src/views/styleguide/*.html'],
      dest: 'build/views/'
    },
    styleguide: {
      src: 'app/src/views/styleguide/*.html',
      dest: 'build/views/styleguide/'
    },
    project: {
      dest: 'build/project/'
    },
    misc: {
      src: [
        'app/www/robots.txt',
        'app/www/{vendor,null}/**/*.css',
        'app/www/{data,null}/**/*.json',
        'app/www/{project,null}/**/*.xml'
      ],
      dest: 'build/'
    }
  },

  img: {
    src: [
      'app/www/**/*.{png,gif,jpg,jpeg,pdf,ico,svg}',
      'app/www/icons/*',
      '!app/www/loading.png',
      '!app/www/components/**/*'
    ],
    dest: 'build/'
  },

  tinymce: {
    src: 'app/www/{vendor,null}/tinymce/**/*.js',
    dest: 'build/'
  },

  mixpanel: {
    src: 'app/www/{vendor,null}/mixpanel/**/*.js',
    dest: 'build/'
  },

  js: {
    src_build: [
      "app/www/components/angular/angular.min.js",
      "app/www/components/react/react.min.js",
      "app/www/vendor/ngReact/ngReact.min.js",
      "app/www/vendor/angular-touch.js",
      "app/www/components/angular-sanitize/angular-sanitize.min.js",
      "app/www/components/angular-route/angular-route.min.js",
      "app/www/components/angular-animate/angular-animate.min.js",
      "app/www/components/angular-cache/dist/angular-cache.min.js",
      "app/www/components/angulartics/dist/angulartics.min.js",
      "app/www/components/angulartics/dist/angulartics-segmentio.min.js",
      "app/www/components/lodash/lodash.min.js",
      "app/www/components/restangular/dist/restangular.min.js",
      "app/www/components/moment/min/moment.min.js",
      "app/www/components/moment-timezone/builds/moment-timezone-with-data-2010-2020.min.js",
      "app/www/components/angular-ui-tinymce/src/tinymce.js",
      "app/www/vendor/ng-tags-input.js",
      "app/www/vendor/TweenLite/TweenLite.js",
      "app/www/vendor/TweenLite/CSSPlugin.js",
      "app/www/vendor/jstz-1.0.4.min.js",
      "app/www/vendor/pusher.min.js",
      "app/www/vendor/PhoneFormat/PhoneFormat.js",
      "app/www/components/jquery/dist/jquery.min.js",
      "app/www/components/foundation/js/foundation/foundation.js",
      "app/www/components/foundation/js/foundation/foundation.offcanvas.js",
      "app/www/components/fastclick/lib/fastclick.js",
      "app/www/components/raven-js/dist/raven.js",
      "app/www/components/sprintf/dist/sprintf.min.js"
    ],
    src_dev: [
      "app/{www,null}/components/angular/angular.js",
      "app/{www,null}/components/react/react-with-addons.js",
      "app/{www,null}/vendor/ngReact/ngReact.js",
      "app/{www,null}/vendor/angular-touch.js",
      "app/{www,null}/components/angular-sanitize/angular-sanitize.js",
      "app/{www,null}/components/angular-route/angular-route.js",
      "app/{www,null}/components/angular-animate/angular-animate.js",
      "app/{www,null}/components/angular-cache/dist/angular-cache.js",
      "app/{www,null}/components/angulartics/dist/angulartics.min.js",
      "app/{www,null}/components/angulartics/dist/angulartics-segmentio.min.js",
      "app/{www,null}/components/lodash/lodash.js",
      "app/{www,null}/components/restangular/dist/restangular.js",
      "app/{www,null}/components/moment/moment.js",
      "app/{www,null}/components/moment-timezone/builds/moment-timezone-with-data-2010-2020.js",
      "app/{www,null}/components/angular-ui-tinymce/src/tinymce.js",
      "app/{www,null}/vendor/ng-tags-input.js",
      "app/{www,null}/vendor/TweenLite/TweenLite.js",
      "app/{www,null}/vendor/TweenLite/CSSPlugin.js",
      "app/{www,null}/vendor/jstz-1.0.4.min.js",
      "app/{www,null}/vendor/pusher.min.js",
      "app/{www,null}/vendor/PhoneFormat/PhoneFormat.js",
      "app/{www,null}/components/jquery/dist/jquery.js",
      "app/{www,null}/components/foundation/js/foundation/foundation.js",
      "app/{www,null}/components/foundation/js/foundation/foundation.offcanvas.js",
      "app/{www,null}/components/fastclick/lib/fastclick.js",
      "app/{www,null}/components/raven-js/dist/raven.js",
      "app/{www,null}/components/sprintf/dist/sprintf.min.js"
    ],
    concat: 'lib.js',
    dest: 'build/app/',
    dest_dev: 'build/'
  },

  config: {
    src: [
      "app/www/javascripts/featureDetection.js",
      "config/environment.js",
      "app/src/config/appEnvironments.coffee",
      "app/src/config/mockSteroids.coffee"
    ],
    concat: 'config.js',
    dest: 'build/'
  },

  html: {
    src: [
      'app/www/**/*.html',
      '!app/www/javascripts/**/*',
      '!app/www/components/**/*'
    ],
    dest: 'build/'
  },

  inject: {
    src: 'gulp/inject.js',
    dest: 'build/',
    replace: {
      from: /<\/head>/g,
      to: '  <script src="/inject.js"></script>\n</head>'
    }
  },

  injectCordova: {
    replace: {
      from: /<!-- INJECT CORDOVA -->/g,
      to: '<script src="cordova.js"></script>'
    }
  },

  server: '../websites/',
  mobiledev: '../websites/mobiledev.meetin.gs',
  mobilebeta: '../websites/mobilebeta.meetin.gs',
  copyToServerFolder: {
    src: 'build/**/*',
  }
};

module.exports = config;
