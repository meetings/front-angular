mtnContentEditable = angular.module "contenteditable", []

mtnContentEditable.directive "contenteditable", [ "$sce", ($sce) ->
  restrict: "A"
  require: "?ngModel"
  link: (scope, element, attrs, ngModel) ->
    return unless ngModel

    read = ->
      html = element.html()
      html = ""  if html is "<br>"
      ngModel.$setViewValue html.replace("&nbsp;"," ")

    ngModel.$render = ->
      element.html $sce.getTrustedHtml(ngModel.$viewValue or "")

    element.on "blur keyup change", ->
      scope.$evalAsync read

    read()
 ]
