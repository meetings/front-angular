mtnRadioButtonList = angular.module "mtnRadioButtonList", []

# Control functions for a list of radio buttons and a checkbox that clears radio button lists value
#
# Options:
#     radionButtonModel: Name of the radio button list's model
#
# Usage:
#    <mtn-radio-button-list radio-button-model="model">
#      Transcluded checkbox and radio button list.
#    </mtn-radio-button-list>
#
mtnRadioButtonList.directive "mtnRadioButtonList", ->
  restrict: 'E'
  replace: true
  transclude: true
  template: '<div ng-class="{\'open\':mtnRadioButtonList.visible}">
               <div ng-transclude></div>
             </div>'
  link: (scope, elem, attrs) ->
    model = attrs.radioButtonModel

    scope.mtnRadioButtonList = {
      visible: false
      toggleVisibility: ->
        scope.mtnRadioButtonList.visible = !scope.mtnRadioButtonList.visible
    }

    scope.$watch(
      () ->
        return scope.mtnRadioButtonList.selected
      (value) ->
        if value && !scope[model].selected?
          scope.mtnRadioButtonList.selected = false
          scope.mtnRadioButtonList.toggleVisibility()
        if !value
          scope[model].selected = null
    )

    scope.$watch(
      () ->
        return scope[model].selected
      (value) ->
        if value
          scope.mtnRadioButtonList.selected = true
    )
