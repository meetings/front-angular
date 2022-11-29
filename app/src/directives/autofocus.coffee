mtnAutoFocus = angular.module "mtnAutofocus", []

mtnAutoFocus.directive "mtnAutofocus", ($timeout) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    $timeout ->
      scope.$apply ->
          elem[0].focus()

    , 700
