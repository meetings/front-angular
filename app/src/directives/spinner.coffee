mtnSpinner = angular.module 'mtnSpinner', []

# Display a spinner
#
# Options:
#  ng-show="expression" : Show spinner when expression is true
#
# Usage:
# <mtn-spinner ng-show="loading">
#
mtnSpinner.directive 'mtnSpinner', ($timeout) ->
  restrict: 'E'
  replace: true
  template: '<div class="spinner-overlay"><div class="spinner-background"><div class="spinner"></div></div></div>'
  scope: {
    ngShow: '='
    hasDelay: '='
  }

  # Delayed addClass is required in order to start animating from opacity 0
  link: (scope, elem, attrs) ->

    bg = angular.element(elem.children()[0])
    spinner = angular.element(bg.children()[0])

    if scope.hasDelay?
      scope.$watch "hasDelay", (hasDelay) ->
        if hasDelay
            bg.removeClass('no-delay')
            spinner.removeClass('no-delay')
        else
            bg.addClass('no-delay')
            spinner.addClass('no-delay')

    scope.$watch "ngShow", (visible) ->
      if visible
        $timeout ->
          bg.addClass('visible')
          spinner.addClass('visible')
        , 5
      else
        $timeout ->
          bg.removeClass('visible')
          spinner.removeClass('visible')
        , 5
