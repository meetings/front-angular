mtnHideParent = angular.module "mtnHideParent", []

# Hide parent element
#
# Usage:
#
#    <ANY hide-parent></ANY>
#
#
mtnHideParent.directive "mtnHideParent", ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    elem.parent()[0].style.display = "none"

