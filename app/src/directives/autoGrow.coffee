mtnAutoGrow = angular.module "autoGrow", []

mtnAutoGrow.directive "autoGrow", ($sce) ->
  restrict: "A"
  require: "?ngModel"
  link: (scope, element, attr, ngModel) ->
    return unless ngModel

    read = ->
      element.css("height", element[0].scrollHeight + "px")
      ngModel.$setViewValue element[0].value

    ngModel.$render = ->
      element.html $sce.getTrustedHtml(ngModel.$viewValue or "")
      element.css("height", element[0].scrollHeight + "px")

    element.on "blur keydown keyup change", ->
      scope.$evalAsync read

    read()
