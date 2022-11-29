mtnProgress = angular.module "mtnProgress", []

# Progress bar and calculated percent
#
# Usage:
# <mtn-upload-progress max="max" value="value"></mtn-upload-progress>

mtnProgress.directive "mtnUploadProgress", () ->
  restrict: 'E'
  replace: true
  scope:
    max: "="
    value: "="

  template: '<div ng-show="uploaded">Uploading: {{ uploaded }}%<progress max="{{ max }}" value="{{ value }}"></progress></div>'

  link: (scope, elem, attrs) ->

    scope.$watch 'value', ->
      update()

    update = ->
      scope.uploaded = parseInt(scope.value / scope.max * 100)
