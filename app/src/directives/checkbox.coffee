mtnCheckbox = angular.module "mtnCheckbox", []

mtnCheckbox.directive "mtnCheckbox", () ->
  restrict: 'E'
  transclude: true
  scope:
    ngModel: '='
    mtnClick: '&'
    mtnSwipeLeft: '&'
    mtnSwipeRight: '&'
    mtnShowSpinner: '='
    name: '@'
  template: '<div>' +
            '<input type="checkbox" name="{{name}}" id="{{name}}" class="ios7toggle" ng-model="checkboxModel">' +
            '<label ng-click="mtnClick()" ng-swipe-left="mtnSwipeLeft()" ng-swipe-right="mtnSwipeRight()"></label>' +
            '<span ng-class="{ \'visible\' : mtnShowSpinner }" class="spinner no-delay"></span>' +
            '<label class="mtnList-toggle-label" ng-click="mtnClick()" ng-swipe-left="mtnSwipeLeft()" ng-swipe-right="mtnSwipeRight()">' +
            '<span ng-transclude></span>' +
            '</label>' +
            '</div>'

  link: (scope, elem, attrs) ->
    inverted = attrs.mtnInvertValue == "true"

    # convert 0|1 values to boolean
    if typeof scope.ngModel == "number"
      scope.ngModel = scope.ngModel == 1

    scope.$watch('ngModel',
      (val) ->
        if inverted
          scope.checkboxModel = !scope.ngModel
        else
          scope.checkboxModel = scope.ngModel
    )
