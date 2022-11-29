calendar = angular.module "calendarModule", ["appConfig", "mtnUtils"]

calendar.service "calendarService", ($log, $q, appConfig, sessionService, deviceUtils) ->

  ############
  # PRIVATE
  ############

  _setTimespan: ->
    @timespanBegin = moment()
    @timespanBeginEpoch = @timespanBegin.format("X")
    @timespanEnd = moment().add('months': 3)
    @timespanEndEpoch = @timespanEnd.format("X")

  # Get events between minDate and maxDate
  _getEventsInRange: (events, minDate, maxDate) ->
    _.filter events, (event) ->
      return moment(event.startDate) >= minDate && moment(event.startDate) < maxDate

  ############
  # PUBLIC
  ############

  getPermissionAsked: ->
    try
      return JSON.parse(localStorage.getItem("__calendar_permission_asked")) ||
        deviceUtils.platform() != "ios"
    catch
      return undefined

  setPermissionAsked: (value) ->
    localStorage.setItem("__calendar_permission_asked", value)

  getTimespanBeginEpoch: ->
    return @timespanBeginEpoch

  getTimespanEndEpoch: ->
    return @timespanEndEpoch

  # Get all calendars from device
  getDeviceCalendars: ->
    deferred = $q.defer()

    window.plugins.calendar.listCalendars(
      (calendars) ->
        $log.debug "Got calendars from device", calendars
        deferred.resolve calendars

      (failure) ->
        $log.error "Failed to get calendars from device", failure
        deferred.reject failure
    )

    return deferred.promise

  # Gat all events from named calendar (iOS only)
  getEventsFromCalendar: (calendar) ->
    deferred = $q.defer()

    window.plugins.calendar.findAllEventsInNamedCalendar(
      calendar.name
      (events) =>
        @_setTimespan()

        # return only next 3 months of events
        eventsInRange = @_getEventsInRange(events, @timespanBegin, @timespanEnd)

        deferred.resolve { calendar: calendar, events: eventsInRange }

      (failure) =>
        $log.error "Failed to get calendar events from calendar", calendarName, failure
        deferred.reject failure
    )

    return deferred.promise

  initIOS: ->
    deferred = $q.defer()

    document.addEventListener "deviceready", =>
      return deferred.reject() unless window.plugins && window.plugins.calendar

      window.plugins.calendar.initialize(
        (data) =>
          deferred.resolve(data)
        (failure) =>
          deferred.reject(failure)
      )

    return deferred.promise

  initAndroid: ->
    deferred = $q.defer()

    document.addEventListener "deviceready", =>
      return deferred.reject() unless window.CalendarConnector

      config = {
        apiBaseUrl: appConfig.api.baseUrl
        pollInterval: appConfig.calendar.pollInterval
      }

      window.CalendarConnector.init(sessionService.getUserId(), sessionService.getToken(), config,
        (data) =>
          deferred.resolve(data)
        (failure) =>
          deferred.reject(failure)
      )

    return deferred.promise

  init: ->
    if deviceUtils.platform() == "ios"
      return @initIOS()
    else if deviceUtils.platform() == "android"
      return @initAndroid()
