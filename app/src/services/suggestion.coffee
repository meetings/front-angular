suggestion = angular.module "suggestionModule", ["appConfig", "calendarModule", "dateHelper", "mtnUtils"]

suggestion.service "suggestionService", ($q, $log, $interval, $timeout, appConfig, calendarService, currentUserService, sessionService, dateHelper, deviceUtils) ->

  ############
  # PRIVATE
  ############

  _getContainerName: (deviceModel) ->
    containerName = ""

    switch deviceModel

      when "iPhone1,1" then containerName = "iPhone 2G"
      when "iPhone1,2" then containerName = "iPhone 3G"
      when "iPhone2,1" then containerName = "iPhone 3GS"
      when "iPhone3,1" then containerName = "iPhone 4"
      when "iPhone3,2" then containerName = "iPhone 4"
      when "iPhone3,3" then containerName = "iPhone 4"      # (CDMA)
      when "iPhone4,1" then containerName = "iPhone 4S"
      when "iPhone5,1" then containerName = "iPhone 5"
      when "iPhone5,2" then containerName = "iPhone 5"      # (GSM+CDMA)
      when "iPhone5,3" then containerName = "iPhone 5c"     # (GSM+CDMA)
      when "iPhone5,4" then containerName = "iPhone 5c"     # (UK+Europe+Asis+China)
      when "iPhone6,1" then containerName = "iPhone 5s"     # (GSM+CDMA)
      when "iPhone6,2" then containerName = "iPhone 5s"     # (UK+Europe+Asis+China)
      when "iPhone7,1" then containerName = "iPhone 6 Plus"
      when "iPhone7,2" then containerName = "iPhone 6"

      when "iPod1,1" then containerName = "iPod Touch"   # (1 Gen)
      when "iPod2,1" then containerName = "iPod Touch"   # (2 Gen)
      when "iPod3,1" then containerName = "iPod Touch"   # (3 Gen)
      when "iPod4,1" then containerName = "iPod Touch"   # (4 Gen)
      when "iPod5,1" then containerName = "iPod Touch"   # (5 Gen)

      when "iPad1,1" then containerName = "iPad"
      when "iPad1,2" then containerName = "iPad 3G"
      when "iPad2,1" then containerName = "iPad 2"       # (WiFi)
      when "iPad2,2" then containerName = "iPad 2"
      when "iPad2,3" then containerName = "iPad 2"       # (CDMA)
      when "iPad2,4" then containerName = "iPad 2"
      when "iPad2,5" then containerName = "iPad Mini"    # (WiFi)
      when "iPad2,6" then containerName = "iPad Mini"
      when "iPad2,7" then containerName = "iPad Mini"    # (GSM+CDMA)
      when "iPad3,1" then containerName = "iPad 3"       # (WiFi)
      when "iPad3,2" then containerName = "iPad 3"       # (GSM+CDMA)
      when "iPad3,3" then containerName = "iPad 3"
      when "iPad3,4" then containerName = "iPad 4"       # (WiFi)
      when "iPad3,5" then containerName = "iPad 4"
      when "iPad3,6" then containerName = "iPad 4"       # (GSM+CDMA)
      when "iPad4,1" then containerName = "iPad Air"     # (WiFi)
      when "iPad4,2" then containerName = "iPad Air"     # (GSM+CDMA)
      when "iPad4,3" then containerName = "iPad Air"     # (GSM+CDMA)
      when "iPad4,4" then containerName = "iPad Mini"    # Retina (WiFi)
      when "iPad4,5" then containerName = "iPad Mini"    # Retina (GSM+CDMA)
      when "iPad4,6" then containerName = "iPad Mini"
      when "iPad4,7" then containerName = "iPad Mini 3"
      when "iPad4,8" then containerName = "iPad Mini 3"
      when "iPad4,9" then containerName = "iPad Mini 3"
      when "iPad5,3" then containerName = "iPad Air 2"
      when "iPad5,3" then containerName = "iPad Air 2"

      when "i386" then containerName = "Simulator"
      when "x86_64" then containerName = "Simulator"

      # Unkown device, just strip numbers from the end
      else containerName = deviceModel.substr(0, deviceModel.indexOf(',') - 1)

    return containerName

  _clearCache: ->
    @eventCache = {}

  _setEventCache: (calendarName, events) ->
    if !@eventCache?
      @eventCache = {}

    @eventCache[calendarName] = JSON.stringify(events)

  _getEventCache: (calendarName) ->
    return null unless @eventCache? && @eventCache[calendarName]

    return @eventCache[calendarName]

  # Compare received events to cached events to determine if new events need to be sent to backend
  _hasNewEvents: (calendarName, events) ->
    eventCache = @_getEventCache(calendarName)

    return true unless eventCache?

    ecString = eventCache

    evtString = JSON.stringify(events)

    return ecString != evtString

  # Concatenate particpant array into '"name" <email>' string
  _formatParticipants: (attendees) ->
    particpants = []

    _.each attendees, (attendee) ->
      email = attendee.url.replace("mailto:", "")
      particpants.push('"' + attendee.name + '" <' + email + '>')

    return particpants.join()

  # Find attendee whose name matches organizer and return that attendee in proper form
  _findOrganizer: (organizer, attendees) ->
    orgAttendee = _.find attendees, (attendee) ->
      return attendee.name == organizer

    if orgAttendee?
      email = orgAttendee.url.replace("mailto:", "")
      return '"' + orgAttendee.name + '" <' + email + '>'

    return null

  # Property names from calendar plugin are different than property names in api,
  # so we need to create new array of events with proper property names
  _prepareEventsForBatchUpdate: (events) ->
    suggestionBatch = []

    _.each(events, (event) =>
      batchEvent = {}
      batchEvent.uid  =             event.calendarItemExternalIdentifier
      batchEvent.title =            event.title
      batchEvent.begin_epoch =      parseInt(event.startDateEpoch)
      batchEvent.end_epoch =        parseInt(event.endDateEpoch)
      batchEvent.description =      event.message
      batchEvent.location =         event.location
      batchEvent.participant_list = @_formatParticipants(event.attendees)

      organizer = @_findOrganizer(event.organizer, event.attendees)
      if organizer?
        batchEvent.organizer = organizer

      suggestionBatch.push batchEvent
    )

    $log.debug "Events prepared for batch import", suggestionBatch
    return suggestionBatch

  # Send suggestions to backend
  _batchUpdateSuggestions: (calendarId, calendarName, isDefault, events) ->

    sourceBatch = {
      source_container_id: device.uuid
      source_container_type: "phone"
      source_container_name: @_getContainerName(device.model)
      source_id_inside_container: calendarId
      source_name: calendarName
      source_is_primary: isDefault
      timespan_begin_epoch: calendarService.getTimespanBeginEpoch()
      timespan_end_epoch: calendarService.getTimespanEndEpoch()

      suggestions: events
    }

    return currentUserService.getRoute().one("suggested_meetings").post("set_for_source_batch", sourceBatch)

  _prepareCalendarsForBatchUpdate: (containerName, containerId, calendars) ->
    suggestionSourceData = {
      container_name: containerName
      container_type: "phone"
      container_id: containerId
      sources: []
    }

    _.each(calendars, (cal) =>

      suggestionSourceData.sources.push({
        name: cal.name
        id_inside_container: cal.id
        is_primary: cal.defaultCalendarForNewEvents
      })
    )

    return suggestionSourceData

  # Horrible mega update function
  _update: ->
    $log.debug "Update suggestions"

    # Get device calendars
    calendarService.getDeviceCalendars().then(
      (suggestionSources) =>

        deferred = $q.defer()

        data = {}
        data.events = []
        data.updateList = []
        data.suggestionSources = suggestionSources

        containerName = @_getContainerName(device.model)
        data.sourceContainer = @_prepareCalendarsForBatchUpdate(containerName, device.uuid, suggestionSources)

        # Get events from calendars
        _.each(data.suggestionSources, (suggestionSource) =>
          data.events.push(calendarService.getEventsFromCalendar(suggestionSource))
        )

        # Wait for all the events to be fetched
        $q.all(data.events).then(
          (suggestions) =>
            data.suggestions = suggestions
            deferred.resolve data
        )

        return deferred.promise

    ).then(
      (data) =>
        # Convert events to suggestions if new events are found
        _.each(data.suggestions, (suggestions) =>
          if @_hasNewEvents(suggestions.calendar.name, suggestions.events)

            $log.debug "Found new events"

            data.updateList.push(
              id: suggestions.calendar.id
              name: suggestions.calendar.name
              defaultCalendarForNewEvents: suggestions.calendar.defaultCalendarForNewEvents
              suggestions: @_prepareEventsForBatchUpdate(suggestions.events)
              events: suggestions.events
            )
        )

        return data

    ).then(
      (data) =>
        deferred = $q.defer()

        # Update suggestion if new events were found
        if data.updateList.length != 0
          $log.debug "Updating suggestions"

          currentUserService.getRoute().one("suggestion_sources").post("set_container_batch", data.sourceContainer).then(
            (success) =>
              deferred.resolve(data)
          )

        return deferred.promise
    ).then(
      (data) =>

        updates = []

        _.each(data.updateList, (batch) =>
          updates.push(@_batchUpdateSuggestions(batch.id, batch.name, batch.defaultCalendarForNewEvents, batch.suggestions).then(
            (data) =>
              $log.debug "Update succesful, refreshing cache"
              # Update events to cache after successful post to api
              @_setEventCache(batch.name, batch.events)
          ))
        )

        $q.all(updates)

    )

  _disconnectAndroid: ->
    deferred = $q.defer()
    CalendarConnector.stopService((result) ->
      if result == "OK"
        CalendarConnector.removeSources((result) ->
          if result == "OK"
            deferred.resolve()

          else
            deferred.reject(result)
        )
      else
        deferred.reject(result)
    )

    return deferred.promise
  ############
  # PUBLIC
  ############

  getCalendarConnectedUsers: ->
    calendarConnected = localStorage.getItem("__calendar_connected")

    if calendarConnected
      return JSON.parse(calendarConnected)
    else
      return []

  setCalendarConnectedUsers: (userIds) ->
    localStorage.setItem("__calendar_connected", JSON.stringify(userIds))

  getCalendarSuggestionsEnabled: ->
    connectedUsers = @getCalendarConnectedUsers()

    return _.contains(connectedUsers, sessionService.getUserId())

  enableCalendarSuggestions: ->
    $log.debug "Adding current user to enabled suggestions list"

    if !@getCalendarSuggestionsEnabled()
      connectedUsers = @getCalendarConnectedUsers()

      connectedUsers.push(sessionService.getUserId())

      @setCalendarConnectedUsers(connectedUsers)

  disableCalendarSuggestions: ->
    $log.debug "Removing current user from enabled suggestions list"

    connectedUsers = @getCalendarConnectedUsers()

    _.remove(connectedUsers, (userId) -> userId == sessionService.getUserId())

    @setCalendarConnectedUsers(connectedUsers)

  updateSources: (user, suggestionSources) ->
    user.source_settings = @enableSelectedSources(suggestionSources)

    return currentUserService.update(user)

  pollForSuggestions: ->
    $log.debug "Starting calendar suggestion polling"

    @pollPromise = @poll =>
      $log.debug "Polling for calendar suggestions"
      @_update()

  stopPollingForSuggestions: ->
    $log.debug "Polling for calendar suggestions canceled"
    @cancelPoll(@pollPromise)
    @pollPromise = null

  # Initialize calendar polling
  poll: (callback) ->
    return $interval(callback, appConfig.calendar.pollInterval)

  # Cancel polling for calendar suggestions
  cancelPoll: (pollPromise) ->
    $interval.cancel pollPromise

  # Connect and sync calendars to app on Android
  syncCalendarsAndroid: ->
    deferred = $q.defer()
    CalendarConnector.startService((result) =>
      if result == "OK"
        $timeout( =>
          CalendarConnector.forceUpdate((result) =>
            if result == "OK"
              deferred.resolve()
              @enableCalendarSuggestions()

            else
              deferred.reject(result)
          )
        , 1000)

      else
        deferred.reject(result)
    )

    return deferred.promise

  # Connect and sync calendars to app on iOS
  syncCalendarsIOS: ->
    @_clearCache()

    return @_update().then(
      (data) =>
        @pollForSuggestions()
        @enableCalendarSuggestions()
    )

  syncCalendars: ->
    if deviceUtils.platform() == "ios"
      return @syncCalendarsIOS()
    else if deviceUtils.platform() == "android"
      return @syncCalendarsAndroid()

  # Disconnect device calendar syncing
  disconnectDeviceCalendar: (containerName, containerId, isCurrentDevice, platform) ->
    if isCurrentDevice && platform == "android"
      @disableCalendarSuggestions()
      return @_disconnectAndroid()

    else
      if isCurrentDevice && platform == "ios"
        @disableCalendarSuggestions()
        @stopPollingForSuggestions()
        @_clearCache()

      suggestionSourceData = @_prepareCalendarsForBatchUpdate(containerName, containerId, [])

      currentUserService.getRoute().one("suggestion_sources").post("set_container_batch", suggestionSourceData).then(
        (data) =>
          $log.debug "set_container_batch succesful", data
        (failure) =>
          $log.debug "set_container_batch failed", failure
      )


  # Convert source list to source_settings object
  enableSelectedSources: (suggestionSources) ->
    enabled = {}
    disabled = {}

    _.each(suggestionSources, (source) ->
      if source.selected_by_default
        enabled[source.uid] = 1
      else
        disabled[source.uid] = 1

      return
    )

    return {
      enabled: enabled
      disabled: disabled
    }

  selectDefaultSources: (suggestionSources) ->
    _.each(suggestionSources, (source) ->
      # Select all default sources
      source.selected_by_default = source.selected_by_default == 1
      return
    )

    return suggestionSources

  # Convert source_settings object to selected items in source list
  selectEnabledSources: (suggestionSources, sourceSettings) ->
    _.each(suggestionSources, (source) ->
      # Select all default sources
      source.selected_by_default = source.selected_by_default == 1

      # If source exists in enabled list, select that too
      if sourceSettings.enabled[source.uid]?
        source.selected_by_default = true

      # If source exists in disabled list, unselect source
      if sourceSettings.disabled[source.uid]?
        source.selected_by_default = false

      return
    )

    return suggestionSources

  isCurrentDeviceCalendarConnected: (suggestionSources) ->
    return _.where(suggestionSources, {container_id: device.uuid }).length > 0
