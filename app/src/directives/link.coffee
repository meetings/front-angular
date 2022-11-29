mtnA = angular.module "mtnA", [ 'appConfig', 'mtnURL' ]

mtnA.directive "mtnA", ($window, appConfig, mtnURL) ->
  restrict: 'E'
  transclude: true
  replace: true
  scope:
    href: '@'
    altHref: '@?'
  template: '<span ng-click="openUrl()" ng-transclude></span>'
  link: (scope, elem, attrs) ->

    scope.openUrl = ->
      mtnURL.open(scope.href, scope.altHref, attrs.target)
