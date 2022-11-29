class SchedulingBaseCtrl

  @$inject =
    [
      "$scope"
      "$rootScope"
      "$window"
      "$log"
      "$location"
      "$q"
      "$filter"
      "$http"
      "$timeout"
      "appConfig"
      "errorHandlerService"
      "SessionRestangular"
      "sessionService"
      "schedulingService"
      "matchmakerService"
      "meetingService"
      "currentUserService"
      "participantService"
      "suggestionService"
      "contactService"
      "schedulingLogService"
      "navigationBarService"
      "pusherService"
      "dateHelper"
      "viewParams"
      "splashscreen"
      "cssClassUtils"
      "deviceUtils"
      "connectivity"
     ]

  constructor: (
      @scope
      @rootScope
      @window
      @log
      @location
      @q
      @filter
      @http
      @timeout
      @appConfig
      @errorHandlerService
      @SessionRestangular
      @sessionService
      @schedulingService
      @matchmakerService
      @meetingService
      @currentUserService
      @participantService
      @suggestionService
      @contactService
      @schedulingLogService
      @navigationBarService
      @pusherService
      @dateHelper
      @viewParams
      @splashscreen
      @cssClassUtils
      @deviceUtils
      @connectivity
    ) ->

    @splashscreen.hide()

    @tab = @viewParams.get("tab") || "scheduling"

    @isDeveloperMenuVisible = @appConfig.isDevelopmentMode
    @participantMaxCountBeforeSummary = @appConfig.meeting.participants.maxCountBeforeSummary

    @s2m = @schedulingService.getScheduling()
    @meeting = @meetingService.getMeeting()

    @_setPristine()

    if _.isEmpty(@s2m) &&
       !@meeting.id? &&
       @location.path() != "/scheduling"
      @location.path("/scheduling")

    if !@s2m.participants? || @s2m.participants.length == 0
      @log.debug "cloning participants"
      @s2m.participants = angular.copy(@meeting.participants)

  ############
  # PRIVATE
  ############

  _path: (path) ->
    @meetingService.setMeeting(@meeting)
    @schedulingService.setScheduling(@s2m)

    @location.path(path)

  _back: ->
    @meetingService.setMeeting(@meeting)
    @schedulingService.setScheduling(@s2m)

    @window.history.back()

  _cancel: ->
    @_revert()
    @window.history.back()

  _setPristine: ->
    @s2mPristine = angular.copy(@s2m)
    @meetingPristine = angular.copy(@meeting)

  _revert: ->
    @schedulingService.setScheduling(@s2mPristine)
    @meetingService.setMeeting(@meetingPristine)
    @s2mPristine = null
    @meetingPristine = null

  _resetS2m: ->
    @s2m = {}
    @schedulingService.setScheduling(@s2m)

  _resetMeeting: ->
    @meeting = @meetingService.getEmptyMeeting()
    @meetingService.setMeeting(@meeting)

  _setLayoutButtons: (doneCallback) ->
    return {
      closeButton:
        title: "Back"
        onClick: =>
          @rootScope.$broadcast("blurInput")

          @_cancel()

      doneButton:
        title: if @viewParams.get("fromReview") then "Done" else "Next"
        onClick: =>
          @rootScope.$broadcast("blurInput")

          doneCallback()
    }

  _fetchLunchScheduler: ->
    @matchmakerService.fetchLunchScheduler()

  _fetchMatchmakers: ->
    @matchmakerService.fetchMatchmakers()

  _getUser: ->
    @currentUserService.get()

  _fetchMeeting: ->
    @meetingService.fetchMeeting(@meeting.id, { image_size: @appConfig.thumbnail.small })

  _fetchSuggestionSources: ->
    @currentUserService.getRoute().all("suggestion_sources").getList()

  _setEnabledSuggestionSources: (sourceSettings) ->
    enabledSources = @suggestionService.selectEnabledSources(@s2m.suggestionSources, sourceSettings)

    @s2m.sources = _.values(
      _(enabledSources).sortBy((source) -> source.name.toLowerCase())
                       .groupBy((source) -> source.container_id).value()
    )

    @s2m.scheduling.source_settings = @suggestionService.enableSelectedSources(enabledSources)
    @_setCalendarCounts(enabledSources)

  _setCalendarCounts: (enabledSources) ->
    @s2m.enabledCalendarsCount = _.where(enabledSources, selected_by_default: true).length
    @s2m.totalCalendarsCount   = enabledSources.length

  ############
  # PUBLIC
  ############

  getBackgroundImageUrl: ( meeting ) ->
    @meetingService.getBackgroundImageUrl( meeting )

  getTypeIconClass: ( meeting ) ->
    @meetingService.getTypeIconClass( meeting )

  handleError: ->
    @error = null

    if @errorHandlerCallback?
      @errorHandlerCallback()

    @errorHandlerCallback = null

class SchedulingIndexCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    # Reset s2m but not meeting every time user is on the first view of the tab
    @_resetS2m()

    # If location equals scheduling tab path, we are on scheduling tab. -> Create empty meeting
    if @location.path() == "/scheduling"
      @_resetMeeting()

    @_setPristine()

    @carouselVisible = @sessionService.getShowCarousel()

    @_setLayout()

    @user = @_getUser()

    if @meeting.current_scheduling_id? && @meeting.current_scheduling_id != 0
      @startFromCurrentScheduling()
    else
      @_initScheduling()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    if @carouselVisible
      @navigationBarService.hide()
      @navigationBarService.hideMenu()
    else
      @navigationBarService.update({
        title: "Find a suitable time"
        buttons:
          left: if @location.path() != "/scheduling" then @navigationBarService.defaultBackButton() else null
      })

  _initScheduling: ->
    @matchmakers = @matchmakerService.getCache()

    @_fetchLunchScheduler().then(
      (data) =>
        @log.debug "Loaded lunch scheduler from local json"
        @matchmakers = data

        @_fetchSchedulingData()
    )

  _fetchSchedulingData: ->
    fetchList = [
      @_fetchSuggestionSources()
      @_fetchMatchmakers()
    ]

    if !@matchmakers?
      @loading = true

    if @meeting.id? && @meeting.meetingDataNotAvailable
      fetchList.push(@_fetchMeeting())
      @loading = true

    @q.all(fetchList).then(
      (data) =>
        @log.debug "Loaded everything succesfully"

        @s2m.suggestionSources = data[0]

          # Show matchmaker templates only for meetin.gs and dicole.com users
        if /@(meetin.gs|dicole.com)/.test(@user.email)
          matchmakers = @matchmakerService.filterMatchmakers(data[1])
          @matchmakers = @matchmakers.concat(matchmakers)

          @matchmakerService.setCache(@matchmakers)

        if data.length > 2
          @meeting = data[2]
          @s2m.agenda = _.find(@meeting.materials, (material) -> material.material_class == 'agenda')

      (failure) =>
        @log.error "Failed to load initial data", failure

        if @connectivity.isOnline()
          @error = @errorHandlerService.handle failure

        @errorHandlerCallback = @_fetchSchedulingData

    ).finally(
      =>
        @loading = false
    )

  _initDefaultSlots: ->
    # Default selected days in custom time view
    @s2m.days = [true,true,true,true,true,false,false]
    beginSecond = 9*60*60
    endSecond = 17*60*60

    @s2m.scheduling.slots = @schedulingService.formatSchedulingSlots(@s2m.days, beginSecond, endSecond)

  _initDefaultTimeSpans: ->
    startDate = @dateHelper.defaultNewSchedulingBeginDate()

    @s2m.availableTimespans = {
      start: startDate
      end: null
    }
    @s2m.scheduling.available_timespans = [{
      start: startDate
    }]

  ############
  # PUBLIC
  ############

  onCarouselComplete: =>
    @navigationBarService.show("Find a suitable time")
    @navigationBarService.showMenu()

  startFromCurrentScheduling: ->
    @s2m.scheduling = @meeting.current_scheduling
    @s2m.scheduling.background_theme = @meeting.background_theme
    @s2m.scheduling.is_scheduling_template = 1

    @s2m.days = @schedulingService.getSelectedDaysFromSlots(@s2m.scheduling.slots)

    @s2m.availableTimespans = _.cloneDeep(@s2m.scheduling.available_timespans)[0]

    if @s2m.availableTimespans.end?
      @s2m.availableTimespans.end -= @dateHelper.oneDayInSeconds

    @s2m.humanizedDuration = @dateHelper.durationString(0, @s2m.scheduling.duration * 60)
    @s2m.selectedDays = _(@s2m.scheduling.slots).pluck("weekday").uniq(true).value()

    @_path("/#{@tab}/meeting/#{@meeting.id}/scheduling/review").replace()

  startNewScheduling: ->
    @s2m.scheduling = {
      is_scheduling_template     : 1
      buffer                     : 30
      duration                   : 60
      time_zone                  : jstz.determine().name()
      source_settings            : @user.source_settings
      background_theme           : 13
      meeting_type               : 15
      organizer_swiping_required : 1
    }

    @_initDefaultSlots()
    @_initDefaultTimeSpans()

    @_path("/scheduling/time")

  selectTemplate: (template) ->
    @s2m.scheduling = template

    @meeting.initial_agenda = template.preset_agenda

    if !@meeting.title_value? || @meeting.title_value == ""
      @meeting.title_value = template.name

    @s2m.days = @schedulingService.getSelectedDaysFromSlots(@s2m.scheduling.slots)

    if @s2m.scheduling.available_timespans?.length > 0
      @s2m.availableTimespans = @s2m.scheduling.available_timespans
    else
      @_initDefaultTimeSpans()

    if !@s2m.scheduling.source_settings?
      @s2m.scheduling.source_settings = @user.source_settings

    if !@s2m.scheduling.time_zone?
      @s2m.scheduling.time_zone = jstz.determine().name()

    @s2m.humanizedDuration = @dateHelper.durationString(0, @s2m.scheduling.duration * 60)
    @s2m.selectedDays = _(@s2m.scheduling.slots).pluck("weekday").uniq(true).value()

    @_path("/scheduling/participants")

class SchedulingTimeCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons()

    @navigationBarService.update({
      title: "Time"
      buttons:
        left: buttons.closeButton
    })

    @navigationBarService.hideMenu()

  _saveTime: (selectedDays, beginSecond, endSecond, defaultTitle) ->
    @s2m.scheduling.slots = @schedulingService.formatSchedulingSlots(selectedDays, beginSecond, endSecond)
    @s2m.selectedDays = _(@s2m.scheduling.slots).pluck("weekday").uniq(true).value()

    @s2m.defaultTitle = defaultTitle

  ############
  # PUBLIC
  ############

  selectTime: (selectedDays, beginSecond, endSecond, defaultTitle) ->
    @_saveTime(selectedDays, beginSecond, endSecond, defaultTitle)

    @_path("/scheduling/duration")

  openTimeEdit: ->
    @_path("/scheduling/customtime")


class SchedulingEditTimeCtrl extends SchedulingTimeCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_timeEditDone)

    @navigationBarService.update({
      title: "Time"
      buttons:
        left: buttons.closeButton
        right: buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _timeEditDone: =>
    selectedDays = @schedulingService.formatSelectedDays(@s2m.days)
    @_saveTime(selectedDays, @s2m.scheduling.slots[0].begin_second, @s2m.scheduling.slots[0].end_second)

    if @viewParams.get("fromReview")
      @viewParams.set({ fromReview: null })
      @_back()
    else
      @_path("/scheduling/duration")

  ############
  # PUBLIC
  ############

  formatTimezone: (timezone) ->
    return @dateHelper.formatTimezone(timezone)

  toggleDayValue: (index) ->
    @s2m.days[index] = !@s2m.days[index]

  setDayValue: (index, value) ->
    @s2m.days[index] = value

class SchedulingDurationCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons()

    @navigationBarService.update({
      title: "Duration"
      buttons:
        left: buttons.closeButton
    })

    @navigationBarService.hideMenu()

  _saveDuration: (duration) ->
    @s2m.scheduling.duration = duration
    @s2m.humanizedDuration = @dateHelper.durationString(0, @s2m.scheduling.duration * 60)

  ############
  # PUBLIC
  ############

  selectDuration: (duration) ->
    @_saveDuration(duration)

    @_path("/scheduling/location")

  openDurationEdit: ->
    @_path("/scheduling/customduration")

class SchedulingEditDurationCtrl extends SchedulingDurationCtrl

  constructor: ->
    super

    @_initDurationDropdowns()
    @_convertToHoursAndMinutes()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_durationEditDone)

    @navigationBarService.update({
      title: "Duration"
      buttons:
        left: buttons.closeButton
        right: buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _initDurationDropdowns: ->
    @s2m.durationHourOptions = [
      { name: "0 hours", value: 0 }
      { name: "1 hour",  value: 1 }
      { name: "2 hours", value: 2 }
      { name: "3 hours", value: 3 }
      { name: "4 hours", value: 4 }
      { name: "6 hours", value: 6 }
      { name: "8 hours", value: 8 }
    ]

    @s2m.durationMinuteOptions = [
      { name: "0 minutes",  value: 0 }
      { name: "15 minutes", value: 15 }
      { name: "30 minutes", value: 30 }
      { name: "45 minutes", value: 45 }
    ]

  _convertToHoursAndMinutes: ->
    hours = parseInt(@s2m.scheduling.duration / 60)
    # Round minutes to nearest 15
    minutes = Math.round((@s2m.scheduling.duration % 60) / 15) * 15
    if minutes == 60
      minutes = 0

    @s2m.durationHours = _.find(@s2m.durationHourOptions, { value: hours })
    @s2m.durationMinutes = _.find(@s2m.durationMinuteOptions, { value: minutes })

  _durationEditDone: =>
    duration = @s2m.durationHours.value * 60 + @s2m.durationMinutes.value
    @_saveDuration(duration)

    if @viewParams.get("fromReview")
      @viewParams.set({ fromReview: null })
      @_back()
    else
      @_path("/scheduling/location")

  ############
  # PUBLIC
  ############

  onDurationChange: ->
    if @s2m.durationHours.value == 0 && @s2m.durationMinutes.value == 0
      @s2m.durationMinutes = @s2m.durationMinuteOptions[1]


class SchedulingLocationCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons()

    @navigationBarService.update({
      title: "Location"
      buttons:
        left: buttons.closeButton
    })

    @navigationBarService.hideMenu()

  ############
  # PUBLIC
  ############

  selectLocation: (preset) ->
    switch preset
      when 1
        name = @_getUser().last_name || @_getUser().name
        @meeting.location_value = "At #{name}'s office"
      when 2
        @meeting.location_value = "Online"
      else
        @meeting.location_value = null

    @_path("/scheduling/participants")

  openLocationEdit: ->
    @_path("/scheduling/customlocation")


class SchedulingEditLocationCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_locationEditDone)

    @navigationBarService.update({
      title: "Location"
      buttons:
        left: buttons.closeButton
        right: buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _locationEditDone: =>
    @_path("/scheduling/participants")


class SchedulingParticipantsCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @contactPermissionTextVisible = !@contactService.getPermissionAsked()

    @user = @_getUser()
    @userCountryId = @currentUserService.getUserPhoneCountryId(@user)

    if !@s2m.participantActions?
      @s2m.participantActions = []

    @_getLatestContacts()
    @_removeUserFromParticipants()

    @_initParticipantListWatcher()
    @_setLayout()


  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_participantSelectDone)

    buttons.doneButton.disabled = @_isEnabledParticipantListEmpty()

    @navigationBarService.update({
      title: "Participants"
      buttons:
        left: buttons.closeButton
        right: if @contactPermissionTextVisible then null else buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _initParticipantListWatcher: ->
    @scope.$watch(
      =>
        return @s2m.participants
      =>
        @_participantListChanged()
    , true)

  _participantListChanged: ->
    @_setLayout()

  _participantSelectDone: =>
    if @_isEnabledParticipantListEmpty()
      @error = @errorHandlerService.handleAppError(@errorHandlerService.EMPTY_CONTACT_LIST)
      return

    @_saveLatestContacts()

    if @viewParams.get("fromReview")
      @viewParams.set({ fromReview: null })
      @_back()
    else
      @_path("/scheduling/review")

  _saveLatestContacts: ->
    user = @_getUser()
    @contactService.setLatestContactsForUser(user.id, @s2m.participants)

  _getLatestContacts: ->
    user = @_getUser()
    @latestContacts = @contactService.getLatestContacts()?[user.id]

  _removeUserFromParticipants: ->
    user = @_getUser()
    _.remove(@s2m.participants, phone: user.phone)
    _.remove(@s2m.participants, email: user.email)

  _isEnabledParticipantListEmpty: ->
    return _.filter(@s2m.participants, (participant) -> return !participant.scheduling_disabled).length == 0

  _confirmParticipantReactivation: (participant) ->
    @confirmDialog = {
      title: "Are you sure?"
      message: "#{participant.name} decided not to participate in this scheduling. Are you sure you want to reactivate the scheduling for #{participant.name}?"
      buttonConfirmCallback: =>
        participant.scheduling_disabled = 0
        @s2m.participantActions.push(type: "enableScheduling", participant: participant)

        @confirmDialog = null
      buttonConfirmCaption: "Activate"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  _participantExists: (participant) ->
    if !participant.scheduling_disabled
      @error = @errorHandlerService.handleAppError(@errorHandlerService.PHONENUMBER_EXISTS)
      return

    else if !participant.scheduling_disabled_by_user_id? || participant.scheduling_disabled_by_user_id == @user.id
      participant.scheduling_disabled = 0
      @s2m.participantActions.push(type: "enableScheduling", participant: participant)
      return

    else
      @_confirmParticipantReactivation(participant)
      return

  ############
  # PUBLIC
  ############

  onAddParticipant: (participant, type) ->
    @log.debug "#{type} participant added", participant

    validatedParticipant = @contactService.isValidParticipant(@s2m.participants, participant, type, @user, @userCountryId)

    if validatedParticipant?.existingParticipant?
      @_participantExists(validatedParticipant.existingParticipant)

    else if validatedParticipant?.error?
      @error = validatedParticipant.error

    else
      @s2m.participants.push(participant)
      @s2m.participantActions.push(type: "addParticipant", participant: participant)

  onRemoveParticipant: (participant) ->
    @log.debug "participant removed", participant

    oldParticipant = _.find(@meeting.participants, id: participant.id)

    if !oldParticipant?
      @log.debug "participant not found in meeting participants"
      _.remove(@s2m.participants, participant)
      _.remove(@s2m.participantActions, participant: participant)

    else
      participant.scheduling_disabled_by_user_id = @user.id
      participant.scheduling_disabled = 1
      @s2m.participantActions.push(type: "disableScheduling", participant: participant)

  initContactPlugin: ->
    @contactService.init().then(
      =>
        @contactService.setPermissionAsked(true)
        @contactPermissionTextVisible = false
        @_setLayout()

      (failure) =>
        @log.error "Failed to initialize contact plugin", failure
        @error = @errorHandlerService.handle failure
    )

class SchedulingEditTimespanCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_timespanEditDone)

    @navigationBarService.update({
      title: "Timespan"
      buttons:
        left: buttons.closeButton
        right: buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _timespanEditDone: =>
    @s2m.scheduling.available_timespans[0][@s2m.dateEditing] = parseInt(@s2m.availableTimespans[@s2m.dateEditing])

    # Add 1 day to the real end time, so user can set start and end date to the same day for one day span
    if @s2m.dateEditing == "end"
      @s2m.scheduling.available_timespans[0][@s2m.dateEditing] += @dateHelper.oneDayInSeconds

    @s2m.dateEditing = null

    @_back()

class SchedulingEditSourcesCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    buttons = @_setLayoutButtons(@_sourceEditDone)

    @navigationBarService.update({
      title: "Calendars"
      buttons:
        left: buttons.closeButton
        right: buttons.doneButton
    })

    @navigationBarService.hideMenu()

  _sourceEditDone: =>
    enabledSources = _.flatten(@s2m.sources)
    @s2m.scheduling.source_settings = @suggestionService.enableSelectedSources(enabledSources)
    @_setCalendarCounts(enabledSources)

    @_back()

  ############
  # PUBLIC
  ############

  openAccountSettings: ->
    @location.path("/settings/calendars")

  toggleSuggestionSourceValue: (type, source) ->
    @log.debug "attrs: ", type, source
    @s2m.sources[type][source].selected_by_default = !@s2m.sources[type][source].selected_by_default

  setSuggestionSourceValue: (type, source) ->
    @log.debug "attrs: ", type, source, value
    @s2m.sources[type][source].selected_by_default = value

class SchedulingReviewCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    if @s2m.schedulingStarted
      @location.path("/scheduling")

    @showBackButton = _.contains(@location.path(), "/meeting/")

    @user = @_getUser()

    @_pushUserToParticipants()
    @_fetchParticipantImages()

    @_setMeetingTitle()

    if !@s2m.suggestionSources?
      @_initReview()

    else
      @_setEnabledSuggestionSources(@s2m.scheduling.source_settings)
      @_setSuggestionsSourceCounts()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    cancelButton =
      title: "Cancel"

      onClick: =>
        @_confirmCancel()

    @navigationBarService.update({
      title: "Review"
      buttons:
        left: if @showBackButton then @navigationBarService.defaultBackButton() else cancelButton
    })

    @navigationBarService.hideMenu()

  _cancelScheduling: =>
    @confirmDialog = null
    @location.path("/scheduling")

    if !@scope.$$phase
      @scope.$apply()

  _confirmCancel: ->
    @confirmDialog = {
      title: "Cancel scheduling?"
      message: "All your selections will be lost. Are you sure you want to cancel the scheduling?"
      buttonConfirmCallback: @_cancelScheduling
      buttonConfirmCaption: "Yes"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "No"
    }

  _initReview: ->
    @loading = true

    @_fetchSuggestionSources().then(
      (data) =>
        @log.debug "Loaded suggestion sources succesfully"

        @s2m.suggestionSources = data

        @_setEnabledSuggestionSources(@s2m.scheduling.source_settings)
        @_setSuggestionsSourceCounts()

      (failure) =>
        @log.error "Failed to load initial data", failure

        @error = @errorHandlerService.handle failure

        @errorHandlerCallback = @_initReview

    ).finally(
      =>
        @loading = false
    )

  _fetchUser: (participant, type) ->
    match = new RegExp(/[^\d]/g)
    params = {
      limit_fields: [
        "id"
        "name"
        "initials"
        "image"
        type
      ]

    }
    params[type] = participant[type]
    @participantService.fetchUser(params).then(
      (data) =>
        @log.debug "Found user", data

        # Remove falsey keys from result and merge it to participant
        _.merge(participant, _.pick(data, _.identity))
    )

  _fetchParticipantImages: ->

    _.each(@s2m.participants, (participant) =>
      if !participant.image?
        if participant.phone
          @_fetchUser(participant, "phone")

        if participant.email
          @_fetchUser(participant, "email")
    )

  _pushUserToParticipants: ->
    @user.rsvp_status = "yes"

    if !_.find(@s2m.participants, phone: @user.phone)? && !_.find(@s2m.participants, email: @user.email)?
      @s2m.participants.unshift(@user)

  _setMeetingTitle: ->
    return unless !@meeting.title_value? || @meeting.title_value == ""

    @meeting.title_value = @meetingService.generateTitle(@s2m.participants, @s2m.defaultTitle)

  _setSuggestionsSourceCounts: ->
    @s2m.enabledCalendarsCount = _.keys(@s2m.scheduling.source_settings.enabled).length
    @s2m.totalCalendarsCount = @s2m.enabledCalendarsCount + _.keys(@s2m.scheduling.source_settings.disabled).length

  _isValidScheduling: ->
    @formError = @schedulingService.isValidScheduling(@s2m)

    if @formError.msg != ""
      @error = @errorHandlerService.handleAppError(@errorHandlerService.INVALID_SCHEDULING, @formError.msg)
      return false

    if _.filter(@s2m.participants, (participant) =>
        return !participant.scheduling_disabled && participant.user_id != @user.id
      ).length == 0

      @error = @errorHandlerService.handleAppError(
        @errorHandlerService.INVALID_SCHEDULING,
        "Please add at least one active participant to the scheduling"
      )
      return false

    return true

  _copyThemeToMeeting: ->
    @meeting.background_theme = @s2m.scheduling.background_theme
    @meeting.meeting_type = @s2m.scheduling.meeting_type

  ############
  # PUBLIC
  ############

  openMeetingEdit: (target) ->
    @viewParams.set({ fromReview: true })
    @_path("/scheduling/meeting/#{@meeting.id}/edit/#{target}")

  openParticipants: ->
    @viewParams.set({ fromReview: true })
    @_path("/scheduling/participants")

  openAgenda: ->
    breadcrumb = encodeURIComponent(@meeting.title_value)

    materialId = @s2m.agenda?.id

    @viewParams.set({ breadcrumb: breadcrumb, isManager: true, materialClass: "agenda" })

    if materialId?
      @_path("/scheduling/meeting/#{@meeting.id}/material/#{materialId}")
    else
      @_path("/scheduling/material")

  openTimespanEdit: (target) ->
    @s2m.dateEditing = target

    if !@s2m.availableTimespans[@s2m.dateEditing]? && @s2m.dateEditing == "end"
      @s2m.availableTimespans[@s2m.dateEditing] = @dateHelper.defaultNewSchedulingEndDate(@s2m.availableTimespans.start)

    @viewParams.set({ fromReview: true })
    @_path("/scheduling/timespan")

  openTimeEdit: ->
    @viewParams.set({ fromReview: true })
    @_path("/scheduling/customtime")

  openDurationEdit: ->
    @viewParams.set({ fromReview: true })
    @_path("/scheduling/customduration")

  openSourceEdit: ->
    @viewParams.set({ fromReview: true })
    @_path("/scheduling/calendars")

  toggleOrganizerSwipingRequired: ->
    @s2m.scheduling.organizer_swiping_required = !@s2m.scheduling.organizer_swiping_required

  setOrganizerSwipingRequired: (value) ->
    @s2m.scheduling.organizer_swiping_required = value

  onScheduleMeeting: ->
    return unless @_isValidScheduling()

    @_copyThemeToMeeting()

    @viewParams.set({ fromReview: true })

    @_path("/scheduling/done")

class SchedulingStartCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    if !@viewParams.get("fromReview")
      @viewParams.set({ fromReview: false })
      @location.path("/scheduling").replace()
      return

    @createNewMeeting = !@meeting.id?

    @_createScheduling()

    @_setLayout()

    @timeout( =>
      @animationFinished = true

      @_redirectToLog()

      @scope.$apply()
    , 4000)

  ############
  # PRIVATE
  ############

  _setLayout: ->

    @navigationBarService.update({
      title: "Starting scheduling"
    })

    @navigationBarService.hideMenu()

  _createScheduling: ->
    @schedulingReady = false

    if @createNewMeeting
      @_createMeeting().then => @_startScheduling()
    else
      @_updateParticipants().then => @_startScheduling()

  _createMeeting: ->
    @meeting.participants = angular.copy(@s2m.participants)
    @s2m.participantActions = null

    @SessionRestangular.all("meetings").post(@meeting).then(
      (data) =>
        @log.debug "created meeting, received meeting data: ", data
        @meeting = data
        @meetingId = data.id
        @meetingService.setMeeting(@meeting)

      (failure) =>
        @log.error "Failed to create meeting", failure
        @error = @errorHandlerService.handle failure
    )

  _updateParticipants: ->
    participantPromises = []
    _.each(@s2m.participantActions, (action) =>
      switch action.type
        when "addParticipant"
          participantPromises.push(@participantService.addParticipant(@meeting.id, action.participant))

        when "enableScheduling"
          participantPromises.push(@participantService.enableScheduling(action.participant))

        when "disableScheduling"
          participantPromises.push(@participantService.disableScheduling(action.participant))
    )

    @q.all(participantPromises).then(
      =>
        @s2m.participantActions = null
    )

  _startScheduling: ->
    @schedulingService.startScheduling(@meeting.id, @s2m.scheduling).then(
      (data) =>
        @log.debug "Scheduling started", data

        @schedulingId = data.id

        @_pollSchedulingReady(data.id)

      (failure) =>
        @log.error "Failed to start scheduling", failure
        @error = @errorHandlerService.handle failure
    )

  _pollSchedulingReady: (schedulingId) ->
    @schedulingService.fetchScheduling(@meeting.id, schedulingId).then(
      (data) =>
        if parseInt(data.failed_epoch) != 0
          @log.error "Failed to start scheduling"
          @error = @errorHandlerService.handleAppError(@errorHandlerService.START_SCHEDULING_FAILED)

        else if parseInt(data.started_epoch) == 0
          @timeout(=>
            @_pollSchedulingReady(schedulingId)
          , @appConfig.scheduling.pollInterval)

        else
          @schedulingReady = true
          @_redirectToLog()

      (failure) =>
        @log.error "Failed to fetch scheduling", failure
        @error = @errorHandlerService.handle failure
    )

  _redirectToLog: ->
    if @animationFinished && @schedulingReady
      @viewParams.set({
        showCloseButton: @createNewMeeting
        showMeetingDetailsButton: true
        showProvideAvailabilityButton: @s2m.scheduling.organizer_swiping_required
      })
      @_path("/timeline/meeting/#{@meeting.id}/scheduling/#{@schedulingId}/log")

  ############
  # PUBLIC
  ############

  handleError: ->
    @error = null

    @window.history.back()

class SchedulingLogCtrl extends SchedulingBaseCtrl

  constructor: ->
    super

    @tab = @viewParams.get("tab") || "timeline"
    @meetingId = @viewParams.get("meetingId")
    @schedulingId = @viewParams.get("schedulingId")
    @showCloseButton = @viewParams.get("showCloseButton")
    @showMeetingDetailsButton = @viewParams.get("showMeetingDetailsButton")
    @showProvideAvailabilityButton = @viewParams.get("showProvideAvailabilityButton") == "true"

    @fullLog = false
    @logData = []

    @_initPusher()
    @_fetchSchedulingLog()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    if @showCloseButton == "true"
      closeButton = {
        title: "Close"
        onClick: =>
          @location.path("/scheduling")

          if !@scope.$$phase
            @scope.$apply()
      }

    @navigationBarService.update({
      title: "Scheduling started"
      buttons:
        left: if !closeButton? then @navigationBarService.buttonToPath("/#{@tab}/meeting/#{@meetingId}") else null
        right: closeButton
    })

    if closeButton?
      @navigationBarService.hideMenu()

  _initPusher: ->
    channelName = @appConfig.pusher.channelName + @sessionService.getUserId()

    pusherNewLogEntryCallback = (data) =>
      if parseInt(data.scheduling_id) == parseInt(@schedulingId) && (@logData.length == 0 || data.entry_id >= _(@logData).pluck("id").last())
        @scope.$apply => @_fetchSchedulingLogWithMinEpoch()

    @pusherService.subscribeAndBind(channelName, "new_scheduling_log_entries", pusherNewLogEntryCallback)

    pusherTimeFoundCallback = (data) =>
      if parseInt(data.scheduling_id) == parseInt(@schedulingId)
        @scope.$apply => @_redirectToThankYouPage()

    @pusherService.subscribeAndBind(channelName, "scheduling_time_found", pusherTimeFoundCallback)

    @scope.$on("$destroy",
      =>
        @pusherService.unbind(channelName, "new_scheduling_log_entries", pusherNewLogEntryCallback)
        @pusherService.unbind(channelName, "scheduling_time_found", pusherTimeFoundCallback)
    )

  _fetchSchedulingLogWithMinEpoch: ->
    latestCreatedEpoch = _(@logData).pluck("created_epoch").max()
    @_fetchSchedulingLog({min_created_epoch: latestCreatedEpoch - 10})

  _fetchSchedulingLog: (params) ->
    params = params || {}

    params.image_size = @appConfig.thumbnail.medium

    @schedulingLogService.fetchAll(@meetingId, @schedulingId, params).then(
      (data) =>
        @logData = @logData.concat(data)
        @logData = _.uniq(@logData, "id")
        @_handleLogEvents(@logData)

      (failure) =>
        @log.error "Failed to load meeting", failure
        @error = @errorHandlerService.handle failure
    )

  _handleLogEvents: (logData) ->
    # Separate user state changes and instruction changes from the rest of the events
    userStateChanges = _.where(logData, {entry_type: "user_state_changed"})
    instructionChanges = _.where(logData, {entry_type: "instruction_changed"})
    logMessages = _.filter(logData, (entry) -> entry.entry_type != "user_state_changed" && entry.entry_type != "instruction_changed")

    @userStates = @schedulingLogService.sortUserStates(userStateChanges)
    @instruction = @schedulingLogService.formatInstructionChanges(instructionChanges)
    @eventLog = @schedulingLogService.formatLogMessages(logMessages)

  _redirectToThankYouPage: ->
    @viewParams.set({
      showCloseButton: @showCloseButton
    })
    return @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/thanks/2")

  ############
  # PUBLIC
  ############

  openMeeting: ->
    @location.path("/timeline/meeting/#{@meetingId}")

  openDateEdit: ->
    @location.path("/timeline/meeting/#{@meetingId}/edit/date").replace()

  openSwipeToMeet: ->
    @viewParams.set({ menuVisible: true })
    @location.path("/timeline/meeting/#{@meetingId}/scheduling/#{@schedulingId}")

  openParticipant: (participantId) ->
    breadcrumb = encodeURIComponent(@meeting.title_value)

    @viewParams.set({
      breadcrumb: breadcrumb
      showCloseButton: @showCloseButton
      schedulingId: @schedulingId
      meetingId: @meetingId
    })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/participants/#{participantId}")

  toggleLogSize: ->
    @fullLog = !@fullLog

  handleError: ->
    @error = null

    @_fetchSchedulingLog()


schedulingApp = angular.module 'schedulingApp',
  [
    'ngRoute'
    'ngAnimate'
    'appConfig'
    'nativeUi'
    'mtnUtils'
    'splashscreen'
    'matchmakerModule'
    'meetingModule'
    'participantModule'
    'schedulingModule'
    'contactModule'
    'suggestionModule'
    'schedulingLogModule'
    'pusherModule'
    'mtnMomentModule'
    'dateHelper'
    'mtnContactPicker'
    'mtnFloatLabel'
    'mtnCheckbox'
    'mtnRadioButtonList'
    'ngTagsInput'
    'mtnTagInput'
    'partials'
    'mtnAnimationReset'
    'mtnCarousel'
    'connectivity'
    'mtnA'
  ]

schedulingApp.controller("SchedulingIndexCtrl",        SchedulingIndexCtrl)
schedulingApp.controller("SchedulingTimeCtrl",         SchedulingTimeCtrl)
schedulingApp.controller("SchedulingEditTimeCtrl",     SchedulingEditTimeCtrl)
schedulingApp.controller("SchedulingLocationCtrl",     SchedulingLocationCtrl)
schedulingApp.controller("SchedulingEditLocationCtrl", SchedulingEditLocationCtrl)
schedulingApp.controller("SchedulingDurationCtrl",     SchedulingDurationCtrl)
schedulingApp.controller("SchedulingEditDurationCtrl", SchedulingEditDurationCtrl)
schedulingApp.controller("SchedulingParticipantsCtrl", SchedulingParticipantsCtrl)
schedulingApp.controller("SchedulingEditTimespanCtrl", SchedulingEditTimespanCtrl)
schedulingApp.controller("SchedulingEditSourcesCtrl",  SchedulingEditSourcesCtrl)
schedulingApp.controller("SchedulingReviewCtrl",       SchedulingReviewCtrl)
schedulingApp.controller("SchedulingStartCtrl",        SchedulingStartCtrl)
schedulingApp.controller("SchedulingLogCtrl",          SchedulingLogCtrl)
