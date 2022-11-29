mtnAutoscroll = angular.module "mtnAutoscroll", []

# Angularjs's own autoscroll attrubute doesn't work with div that has overflow-y: scroll.
# This directive simply listens to $viewContentLoaded event and scrolls target
# element to top every time the view changes.
#
# $timeout is required by iOS. Without timeout this autoscroll works only the first time a view is loaded.
#
mtnAutoscroll.directive "mtnAutoscroll", ($timeout) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->

    scope.$on("$viewContentLoaded", ->
      $timeout( ->
        elem[0].scrollTop = 0
      )
    )
