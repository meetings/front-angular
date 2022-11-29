epochToMoment = angular.module 'epochToMoment', ['dateHelper']

# Formats an epoch timestamp to a human readable date with MomentJS.
# For formatting options see: http://momentjs.com/
#
# Options:
#     is-current-year                  : Is epoch current year
#     epoch-format-if-current-year="x" : Format using "x" if given date is in current year
#     UTC                              : Parse moment in UTC.
#
# Usage: (With model)
#
#    <div ng-model="meeting.begin_epoch"
#         epoch-model
#         epoch-format="MMM Do YYYY"
#         UTC="true"
#         is-current-year="true">
#         epoch-format-if-current-year="MMM DD">
#    </div>
#
epochToMoment.directive 'epochModel', ->

  require: 'ngModel'
  restrict: 'A'
  scope: {}

  link: (scope, elem, attrs, ngModel) ->
    format =
      if attrs.epochFormatIfCurrentYear && attrs.isCurrentYear == "true"
        attrs.epochFormatIfCurrentYear
      else
        attrs.epochFormat

    UTCMode = attrs.utc == "true"

    converted = (epoch, format) ->
      if UTCMode
        moment.unix(epoch).utc().format(format)
      else
        moment.unix(epoch).format(format)

    # Presentation data --> model data
    ngModel.$parsers.unshift (data) ->
      if UTCMode
        moment(data).utc().format("X")
      else
        moment(data).format("X")

    # Model data --> presentation data
    ngModel.$formatters.unshift (data) ->
      return converted(data, format)

    ngModel.$render = ->
      elem.text ngModel.$viewValue


# Like epochModel but the value is given as an element attribute (without 2-way binding).
#
# Options:
#     epoch-format-if-current-year="x" : Format using "x" if given date is in current year
#
# Usage: (Without model)
#
#    <div class="day"
#          epoch
#          epoch-data="meeting.begin_epoch"
#          epoch-format="MMM DD, YYYY"
#          epoch-format-if-current-year="MMM DD">
#    </div>
#
epochToMoment.directive 'epoch', (dateHelper) ->
  restrict: 'AE'
  scope:
    epochData: "="

  link: (scope, elem, attrs) ->

    format =
      if attrs.epochFormatIfCurrentYear && dateHelper.isEpochThisYear(scope.epochData)
        attrs.epochFormatIfCurrentYear
      else
        attrs.epochFormat

    converted = (epoch, format) ->
      moment.unix(epoch).format(format)

    update = (epoch, format) ->
      elem.text converted(epoch, format)

    update(scope.epochData, format)


# Formats meeting begin and end dates from epoch.
# Preserves meeting duration by changing end date accordingly when begin date is changed.
#
#######
# KNOWN ISSUE:
#   Directive cannot be used in the same view with other directives that access the same model!
#
#   In some cases you can use the directive from a subpage with "ng-if" (see meeting#show),
#   to prevent it from messing up the model for other directives.
#
#   In order to fix this, the directive should be split up to several (smaller) directives of which
#   each have only one responsibility. They need to use a shared but isolated scope which will not mess up
#   other directives watching the same model for changes.
#
#   For ideas, see the "duration" directive which uses child-directives with a shared scope.
#
#######
#
#
# Attributes:
#   mtn-preserve-duration     = toggle preserve duration on
#   mtn-ensure-min-duration   = toggle ensure minimun duration on
#   mtn-model-begin           = begin time in epoch format
#   mtn-model-end             = end time in epoch format
#
# Usage:
#   <mtn-datetime-input ng-model="show.meeting.end_epoch"
#                mtn-preserve-duration
#                mtn-ensure-min-duration
#                mtn-model-begin="show.meeting.begin_epoch"
#                mtn-model-end="show.meeting.end_epoch">
#   </mtn-datetime-input>
#
# Please note: You must use an explicit closing tag, using <input/> will break the rest of the view.
#
epochToMoment.directive 'mtnDatetimeInput', (dateHelper) ->

  require: 'ngModel'
  restrict: 'E'
  replace: true
  template: '<input type="datetime-local"/>'
  scope:
    ngModel: '='
    modelBegin: '=mtnModelBegin'
    modelEnd: '=mtnModelEnd'
  link: (scope, elem, attrs, ngModel) ->

    # WebKit requires this format for datetime-local
    format = "YYYY-MM-DDTHH:mm:ss"

    initWatchers = ->
      if attrs.mtnPreserveDuration?
        # Watch begin value for changes and change end value accordingly to preserve duration
        scope.$watch 'modelBegin', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          oldValue = parseInt oldValue
          end = parseInt scope.modelEnd

          duration = end - oldValue

          if !scope.disableNextPreserveDuration
            scope.modelEnd = newValue + duration

          scope.disableNextPreserveDuration = false

      if attrs.mtnEnsureMinDuration?
        # Watch end value for changes and change begin value if duration would become negative
        scope.$watch 'modelEnd', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          durationStartPoint = parseInt scope.modelBegin

          duration = 15 * 60

          if newValue <= durationStartPoint
            scope.disableNextPreserveDuration = true
            scope.modelBegin = newValue - duration

      # Reset begin and end values to next noon and set 1 h duration
      scope.$watch 'ngModel', (value) ->
        if value is "Invalid date" or value is ""
          elem[0].blur()
          scope.disableNextPreserveDuration = true

          scope.modelBegin = dateHelper.defaultNewMeetingBeginDate()
          scope.modelEnd = dateHelper.defaultNewMeetingEndDate(scope.modelBegin)

    converted = (epoch, format) ->
      moment.unix(epoch).format(format)

    # Presentation data --> model data
    ngModel.$parsers.unshift (data) ->
      moment(data).format("X")

    # Model data --> presentation data
    ngModel.$formatters.unshift (data) ->
      return converted(data, format)

    initWatchers()


# Html date input that handles values in seconds.
# Preserves time span by changing end time accordingly when begin time is changed.
#
# Attributes:
#   mtn-preserve-duration     = toggle preserve duration on
#   mtn-ensure-min-duration   = toggle ensure minimun duration on
#   mtn-model-begin           = begin time in seconds
#   mtn-model-end             = end time in seconds
#
# Usage:
#   <mtn-date-input ng-model="index.end_second"
#                   mtn-preserve-duration
#                   mtn-ensure-min-duration
#                   mtn-model-begin="index.begin_second"
#                   mtn-model-end="index.end_second">
#   </mtn-date-input>
#
# Please note: You must use an explicit closing tag, using <input/> will break the rest of the view.
#
epochToMoment.directive 'mtnDateInput', (dateHelper) ->
  require: 'ngModel'
  restrict: 'E'
  replace: true
  template: '<input type="date"/>'
  scope:
    ngModel: '='
    modelBegin: '=mtnModelBegin'
    modelEnd: '=mtnModelEnd'
  link: (scope, elem, attrs, ngModel) ->

    format = "YYYY-MM-DD"

    initWatchers = ->
      if attrs.mtnPreserveDuration?
        # Watch begin value for changes and change end value accordingly to preserve duration
        scope.$watch 'modelBegin', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          oldValue = parseInt oldValue
          end = parseInt scope.modelEnd

          duration = end - oldValue

          if !scope.disableNextPreserveDuration
            scope.modelEnd = newValue + duration

          scope.disableNextPreserveDuration = false

      if attrs.mtnEnsureMinDuration?
        # Watch end value for changes and change begin value if duration would become negative
        scope.$watch 'modelEnd', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          durationStartPoint = parseInt scope.modelBegin

          duration = 60 * 60 * 24 * 30

          if newValue <= durationStartPoint
            scope.disableNextPreserveDuration = true
            scope.modelBegin = newValue - duration

    converted = (epoch, format) ->
      moment.unix(epoch).format(format)

    # Presentation data --> model data
    ngModel.$parsers.unshift (data) ->
      moment(data).format("X")

    # Model data --> presentation data
    ngModel.$formatters.unshift (data) ->
      return converted(data, format)

    initWatchers()


# Html time input that handles values in seconds.
# Preserves time span by changing end time accordingly when begin time is changed.
#
# Attributes:
#   mtn-preserve-duration     = toggle preserve duration on
#   mtn-ensure-min-duration   = toggle ensure minimun duration on
#   mtn-model-begin           = begin time in seconds
#   mtn-model-end             = end time in seconds
#
# Usage:
#   <mtn-time-input ng-model="index.end_second"
#                mtn-preserve-duration
#                mtn-ensure-min-duration
#                mtn-model-begin="index.begin_second"
#                mtn-model-end="index.end_second">
#   </mtn-time-input>
#
# Please note: You must use an explicit closing tag, using <input/> will break the rest of the view.
#
epochToMoment.directive 'mtnTimeInput', (dateHelper) ->
  require: 'ngModel'
  restrict: 'E'
  replace: true
  template: '<input type="time"/>'
  scope:
    ngModel: '='
    modelBegin: '=mtnModelBegin'
    modelEnd: '=mtnModelEnd'
  link: (scope, elem, attrs, ngModel) ->

    format = "HH:mm"

    initWatchers = ->
      if attrs.mtnPreserveDuration?
        # Watch begin value for changes and change end value accordingly to preserve duration
        scope.$watch 'modelBegin', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          oldValue = parseInt oldValue
          end = parseInt scope.modelEnd

          duration = end - oldValue

          if !scope.disableNextPreserveDuration
            scope.modelEnd = newValue + duration

          scope.disableNextPreserveDuration = false

      if attrs.mtnEnsureMinDuration?
        # Watch end value for changes and change begin value if duration would become negative
        scope.$watch 'modelEnd', (newValue, oldValue) ->
          if isNaN(newValue) || isNaN(oldValue)
            return

          newValue = parseInt newValue
          durationStartPoint = parseInt scope.modelBegin

          duration = 15 * 60

          if newValue <= durationStartPoint
            scope.disableNextPreserveDuration = true
            scope.modelBegin = newValue - duration

    converted = (epoch, format) ->
      moment.unix(epoch).utc().format(format)

    # Presentation data --> model data
    ngModel.$parsers.unshift (data) ->
      moment.duration(data).asSeconds()

    # Model data --> presentation data
    ngModel.$formatters.unshift (data) ->
      return converted(data, format)

    initWatchers()


# Returns a string which represents the duration between "begin" and "end" directives.
#
# Usage:
#    <duration>
#      <begin ng-model="meeting.begin_epoch"></begin>
#      <end ng-model="meeting.end_epoch"></end>
#    </duration>
epochToMoment.directive 'duration', (dateHelper) ->
  restrict: 'E'
  scope: true

  controller: ($scope) ->
    setBegin: (begin) ->
      $scope.begin = begin

    setEnd: (end) ->
      $scope.end = end


  link: (scope, elem, attrs) ->

    scope.$watch 'begin', ->
      update()

    scope.$watch 'end', ->
      update()

    update = ->
      elem.text dateHelper.durationString(scope.begin, scope.end)


epochToMoment.directive 'begin', ->
  restrict: 'E'
  require: ['ngModel', '^duration']
  scope: true

  link: (scope, elem, attrs, ctrls) ->
    ngModel = ctrls[0]
    duration = ctrls[1]

    ngModel.$formatters.unshift (data) ->
      duration.setBegin(data)

    ngModel.$render = ->
      return duration.setBegin(ngModel.$modelValue)


epochToMoment.directive 'end', ->
  restrict: 'E'
  require: ['ngModel', '^duration']
  scope: true

  link: (scope, elem, attrs, ctrls) ->
    ngModel = ctrls[0]
    duration = ctrls[1]

    ngModel.$formatters.unshift (data) ->
      duration.setEnd(data)

    ngModel.$render = ->
      return duration.setEnd(ngModel.$modelValue)
