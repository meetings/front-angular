mtnMoment = angular.module "mtnMomentModule", []

# Display value in any moment unit and format.
#
# Attributes:
#   mtn-format-unit-to-moment = format string
#   unit                      = moment unit
#   value                     = value to format
#
# Usage:
#   <span mtn-format-unit-to-moment="dddd"
#         value="1"
#         unit="day">
#   </span>
#
mtnMoment.directive "mtnFormatUnitToMoment", ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    elem.text(moment().set(attrs.unit, attrs.value).format(attrs.mtnFormatUnitToMoment))
