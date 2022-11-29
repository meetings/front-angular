mtnFloatLabel = angular.module "mtnFloatLabel", []

mtnFloatLabel.directive "mtnFloatLabel", () ->
  restrict: 'EA'
  transclude: true
  replace: true
  scope: true
  require: 'ngModel'
  template: '<label class="float-label {{ requiredClass }}" ng-model="ngModel" ng-show="isVisible"">{{labelText}}</label>'

  link: (scope, elem, attrs, ngModel) ->
    input = document.getElementById(attrs.for)
    $input = angular.element(input)
    scope.isVisible = false
    scope.ngModel = input.getAttribute("ng-model")
    scope.labelText = input.getAttribute("placeholder") || "Placeholder not found"
    scope.requiredClass = if (input.hasAttribute("required") || $input.hasClass("required")) then "required" else ""

    input.onfocus = () ->
      elem.addClass("hasFocus")

    input.onblur = () ->
      elem.removeClass("hasFocus")

    ngModel.$render = () ->
      isEmpty = ngModel.$isEmpty(input.value)

      ngModel.$viewValue = input.value
      ngModel.$modelValue = input.value

      scope.isVisible = !isEmpty
