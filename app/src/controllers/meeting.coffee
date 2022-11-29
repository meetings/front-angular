# Timeline tab
#
class MeetingBaseCtrl
  @$inject =
    [ "$scope"
      "$rootScope"
      "$log"
      "$q"
      "$location"
      "$window"
      "$timeout"
      "jsonMsgChannel"
      "meetingGroupUtils"
      "appConfig"
      "SessionRestangular"
      "sessionService"
      "currentUserService"
      "errorHandlerService"
      "meetingService"
      "materialService"
      "participantService"
      "calendarService"
      "suggestionService"
      "pusherService"
      "navigationBarService"
      "dateHelper"
      "removeTinyMCE"
      "viewParams"
      "deviceUtils"
      "connectivity"
      "mtnURL"
     ]

  constructor: (@scope
                @rootScope
                @log
                @q
                @location
                @window
                @timeout
                @jsonMsgChannel
                @meetingGroupUtils
                @appConfig
                @SessionRestangular
                @sessionService
                @currentUserService
                @errorHandlerService
                @meetingService
                @materialService
                @participantService
                @calendarService
                @suggestionService
                @pusherService
                @navigationBarService
                @dateHelper
                @removeTinyMCE
                @viewParams
                @deviceUtils
                @connectivity
                @mtnURL) ->

    @tab = @viewParams.get("tab")

    @_initVariables()
    @_initUser()

    @navigationBarService.showMenu()

  _initVariables: ->
    @loading = false
    @error = null

    @isDevelopmentMode = @appConfig.isDevelopmentMode

    @participantMaxCountBeforeSummary = @appConfig.meeting.participants.maxCountBeforeSummary

  _initUser: ->
    @userRoute = @currentUserService.getRoute()

    @user = @currentUserService.get()

class MeetingIndexCtrl extends MeetingBaseCtrl

  constructor: ->
    super

    @timelineLoaded = false
    @ungroupedMeetings = {}
    @meetings = null
    @showUpcoming = !@location.search().tab? || @location.search().tab == 'upcoming'
    @newSuggestionsButtonVisible = false

    @_initMeetings()
    @_initMessageListener()
    @_initPusher()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.show("Timeline")

    addButton = {
      imagePath: "images/add@2x.png"
      onClick: =>
        @_addNewMeeting()
    }

    @navigationBarService.update({
      buttons:
        right: addButton
    })

  _initMessageListener: ->
    # Enable back button functionality on timeline when tab is changed
    @scope.$on "$routeUpdate", =>
      @showUpcoming = !@location.search().tab? || @location.search().tab == "upcoming"

    @scope.$on "$destroy", =>
      @log.debug "[timeline] destroyed, unsubscribing MsgChannel"
      @jsonMsgChannel.unsubscribe(@msgChannel)

    @msgChannel = @jsonMsgChannel.subscribe (data) =>
      @log.debug "[timeline] received postmessage:", data?.event, data

      @reload() if data?.event == "reloadTimeline"

      @_removeMeetingWithId(data.id) if data?.event == "removeTimelineMeeting"

      @_calendarConnected() if data?.event == "calendarConnected"

      @_calendarDisconnected() if data?.event == "calendarDisconnected"

      @_addNewMeeting() if data?.event == "addMeeting"

      @_fetchMoreMeetings() if data?.event == "fetchMoreMeetings"

  _initPusher: ->
    channelName = @appConfig.pusher.channelName + @sessionService.getUserId()
    eventName = "new_suggestions"
    pusherCallback = (data) =>
      @_fetchNewSuggestions()

    @pusherService.subscribeAndBind(channelName, eventName, pusherCallback)

    @scope.$on("$destroy",
      =>
        @pusherService.unbind(channelName, eventName, pusherCallback)
    )

  _addNewMeeting: ->
    @loading = true
    @suggestionBtnWorking = "new"

    @SessionRestangular.all("meetings").post().then(
      (data) =>
        @log.debug "created meeting, received meeting data: ", data
        @open data
        @_addMeeting(data)
    ).finally(
      =>
        @loading = false
        @suggestionBtnWorking = null
    )

  # Add new meeting to timeline
  _addMeeting: (meeting) ->
    @ungroupedMeetings.push meeting

    @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

  # Replace existing meeting "oldMeeting" with given meeting "newMeeting".
  # All attributes of "oldMeeting" must be unmodified in order to find it.
  _replaceMeeting: (oldMeeting, newMeeting) ->
    @ungroupedMeetings = _.without @ungroupedMeetings, oldMeeting
    @ungroupedMeetings.push newMeeting

    @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

  # Remove existing "meeting" from timeline.
  # All attributes of "meeting" must be unmodified in order to find it.
  _removeMeeting: (meeting) ->
    @ungroupedMeetings = _.without @ungroupedMeetings, meeting

    @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

  # Remove existing "meeting" with matching id from timeline.
  # Because of @scope.$apply this should be used only with postmessages
  _removeMeetingWithId: (meetingId) ->
    @scope.$apply =>
      @ungroupedMeetings = _.remove @ungroupedMeetings, (meeting) -> meeting.id != meetingId

      @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

  _resetInfiniteScrollVariables: ->
    @fetchingMore = false

    @pastLimit = @appConfig.timeline.fetchMoreMeetingsLimit
    @pastOffset = 0

    @upcomingLimit = @appConfig.timeline.fetchMoreMeetingsLimit
    @upcomingOffset = 0
    @suggestedOffset = 0

    @upcomingInfiniteSrcollEnabled = true
    @pastInfiniteSrcollEnabled = true

    @suggestionMaxDate = @dateHelper.thisWeekEndEpoch()

  _initMeetings: ->
    @_resetInfiniteScrollVariables()

    @meetings = @meetingService.getCache()

    if !@meetings?
      @loading = true
      @_fetchAll()

    else
      @timelineLoaded = true

      @timeout( =>
        @_fetchAll()
      , 1000)


  _fetchAll: ->
    initialUpcomingLimit = @appConfig.timeline.initialMeetingsLimit
    initialPastLimit = @appConfig.timeline.initialMeetingsLimit

    @error = null

    @q.all([
      @meetingService.fetchScheduled(@userRoute, {
        sort: 'asc'
        include_draft: 1
        start_min: @dateHelper.todayEpoch()
        limit: initialUpcomingLimit
        image_size: @appConfig.thumbnail.small
      })
      @meetingService.fetchScheduled(@userRoute, {
        sort: 'desc'
        include_draft: 1
        start_max: @dateHelper.todayEpoch()
        limit: initialPastLimit
        offset: @pastOffset
        image_size: @appConfig.thumbnail.small
      })
      @meetingService.fetchSuggested(@userRoute, {
        sort: 'asc'
        include_draft: 1
        start_min: @dateHelper.todayEpoch()
        limit: initialUpcomingLimit
        image_size: @appConfig.thumbnail.small
      })
      @meetingService.fetchUnscheduled(@userRoute)

    ]).then(
      (meetingData) =>
        upcoming = meetingData[0]
        scheduledPast = meetingData[1]
        suggested = meetingData[2]
        unscheduled = meetingData[3]

        @upcomingOffset = upcoming.length
        @suggestedOffset = suggested.length
        @pastOffset = scheduledPast.length

        @scheduledUpcoming = _(upcoming).union(suggested)
                                         .sortBy((meeting) -> parseInt(meeting.begin_epoch))
                                         .value()

        scheduledUpcomingSpliced = @scheduledUpcoming.splice(0, initialUpcomingLimit)

        @ungroupedMeetings = _(scheduledUpcomingSpliced).union(scheduledPast, unscheduled)
                                                        .sortBy((meeting) -> parseInt(meeting.begin_epoch))
                                                        .value()

        @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

        @meetingService.setCache(@meetings)


        if scheduledUpcomingSpliced.length
          # Max date for _fecthNewSuggestions()
          @suggestionMaxDate = _.max(scheduledUpcomingSpliced, (meeting) -> parseInt(meeting.begin_epoch)).begin_epoch

        @timelineLoaded = true

      (failure) =>
        @log.error "[timeline] load error:", failure

        if @connectivity.isOnline() || !@meetings?
          @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false

        @jsonMsgChannel.publishTo "PullToRefresh", JSON.stringify(
          event: "didFecthAll",
        )
    )

  _fetchNextUpcoming: ->
    @fetchingMore = true
    @q.all([
      @meetingService.fetchScheduled(@userRoute, {
        sort: 'asc'
        include_draft: 1
        start_min: @dateHelper.todayEpoch()
        limit: @upcomingLimit
        offset: @upcomingOffset
        image_size: @appConfig.thumbnail.small
      })
      @meetingService.fetchSuggested(@userRoute, {
        sort: 'asc'
        start_min: @dateHelper.todayEpoch()
        limit: @upcomingLimit
        offset: @suggestedOffset
        image_size: @appConfig.thumbnail.small
      })
    ]).then(
      (meetingData) =>
        upcoming = meetingData[0]
        suggested = meetingData[1]

        @upcomingOffset += upcoming.length
        @suggestedOffset += suggested.length

        @scheduledUpcoming = _(@scheduledUpcoming).union(upcoming, suggested)
                                         .sortBy((meeting) -> parseInt(meeting.begin_epoch))
                                         .value()

        scheduledUpcomingSpliced = @scheduledUpcoming.splice(0, @upcomingLimit)

        @ungroupedMeetings = _(@ungroupedMeetings).union(scheduledUpcomingSpliced)
                                                        .sortBy((meeting) -> parseInt(meeting.begin_epoch))
                                                        .value()

        @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

        if scheduledUpcomingSpliced.length
          # Max date for _fecthNewSuggestions()
          @suggestionMaxDate = _.max(scheduledUpcomingSpliced, (meeting) -> parseInt(meeting.begin_epoch)).begin_epoch

        if meetingData[0].length == 0 && meetingData[1].length == 0
          @upcomingInfiniteSrcollEnabled = false

      (failure) =>
        @log.error "[timeline] error:", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @fetchingMore = false
    )

  _fetchNextPast: ->
    @fetchingMore = true

    @meetingService.fetchScheduled(@userRoute, {
      sort: 'desc'
      include_draft: 1
      start_max: @dateHelper.todayEpoch()
      limit: @pastLimit
      offset: @pastOffset
    }).then(
      (meetingData) =>
        scheduledPast = meetingData

        @pastOffset += scheduledPast.length

        @ungroupedMeetings = _.union(@ungroupedMeetings, scheduledPast)
        @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings

        if meetingData.length == 0
          @pastInfiniteSrcollEnabled = false

      (failure) =>
        @log.error "[timeline] error:", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @fetchingMore = false
    )

  _fetchNewSuggestions: ->
    @meetingService.fetchSuggested(@userRoute, {
        sort: 'asc'
        start_min: @dateHelper.todayEpoch()
        start_max: @suggestionMaxDate
        image_size: @appConfig.thumbnail.small
      }).then(
      (meetingData) =>
        @log.debug "[timeline] New suggestions loaded successfully", meetingData

        if meetingData.length == 0
          @log.debug "No suggestions found, remove old suggestions from timeline"
          _.remove(@ungroupedMeetings, 'is_suggested_meeting')

          @newSuggestionsButtonVisible = true

          return

        updateInstantly = false

        _.each(@ungroupedMeetings, (meeting, index, list) =>

          # Check only suggested meetings
          return true unless meeting.is_suggested_meeting

          existingMeeting = _.where(meetingData, { 'id': meeting.id })[0]

          if !existingMeeting?
            @log.debug "Suggestion not found in new suggestions, remove old suggestion from timeline"
            list[index] = { removed: 1 }
            updateInstantly = false

            return true

          # If new meeting matches old meeting, continue to the next one
          else if existingMeeting? && _.isEqual(meeting.originalElement, existingMeeting.originalElement)
            updateInstantly = true
            return true

          else if existingMeeting? && window.innerHeight - document.querySelector('#timeline_list_item_' + existingMeeting.id).getBoundingClientRect().top < 0
            @log.debug "first element is below viewport bottom, update everything"

            existingMeeting = null
            updateInstantly = true

            return false

          else
            @log.debug "first element is above viewport bottom, wait for user to update"

            existingMeeting = null
            updateInstantly = false

            return false
        )

        # clean up ungrouped meetings
        _.remove(@ungroupedMeetings, 'removed')

        @ungroupedMeetings = _(meetingData).union(@ungroupedMeetings)
                                           .uniq('id')
                                           .value()

        if updateInstantly
          @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings
        else
          @newSuggestionsButtonVisible = true

      (failure) =>
        @log.error "[timeline] New suggestions failed loading, failing silently", failure
    )

  _isUpcomingInfiniteSrcollEnabled: ->
    return !@fetchingMore &&
            @upcomingInfiniteSrcollEnabled &&
            @hasUpcomingMeetings()

  _isPastInfiniteSrcollEnabled: ->
    return !@fetchingMore &&
            @pastInfiniteSrcollEnabled &&
            @hasPastMeetings()

  #############
  # PUBLIC
  #############

  handleError: ->
    @reload()

  reload: ->
    @error = null

    if @connectivity.isOnline()
      @_initMeetings()

  ptrCallback: ->
    @_fetchAll()

  fetchMoreMeetings: ->
    if @timelineLoaded
      if @showUpcoming && @_isUpcomingInfiniteSrcollEnabled()
        @_fetchNextUpcoming()
      if !@showUpcoming && @_isPastInfiniteSrcollEnabled()
        @_fetchNextPast()

  hasUpcomingMeetings: ->
    return @hasMeetings(@meetings.today) ||
           @hasMeetings(@meetings.unscheduled) ||
           @hasMeetings(@meetings.thisWeekUpcoming) ||
           @hasMeetings(@meetings.nextWeek) ||
           @hasMeetings(@meetings.furtherInFuture)

  hasPastMeetings: ->
    return @hasMeetings(@meetings.yesterday) ||
           @hasMeetings(@meetings.thisWeekBefore) ||
           @hasMeetings(@meetings.lastWeek) ||
           @hasMeetings(@meetings.furtherInPast)

  hasMeetings: (list) ->
    not _.isEmpty list

  createSuggested: (meeting) =>
    @meetingService.createSuggested(meeting.id).then(
      (data) =>
        @log.debug "created suggestion, received meeting data: ", data
        @log.debug "meeting.id: #{meeting.id} -- data.id: #{data.id}"
        @open data
        @_replaceMeeting meeting, data

      (failure) =>
        @log.warn "Failed creating a suggested meeting", failure
        @error = @errorHandlerService.handle failure
    )

  hideSuggested: (meeting) ->
    @confirmDialog = null

    @meetingService.hideSuggested(meeting.id).then(
      (data) =>
        @log.debug "Removing suggested meeting from timeline with data", meeting, data
        @_removeMeeting meeting

      (failure) =>
        @log.warn "Failed hiding a suggested meeting", failure
        @error = @errorHandlerService.handle failure
    )

  openOrSuggest: (meeting) =>
    if meeting.is_suggested_meeting
      @suggest(meeting)

    else
      @open(meeting)

  open: (meeting) ->
    @meetingService.setMeeting(meeting)
    @location.path("/timeline/meeting/" + meeting.id)

  suggest: (meeting) ->
    suggestEvent = new CustomEvent("suggestMeeting",
      detail:
        meetingId: meeting.id
      bubbles: false
    )
    window.dispatchEvent(suggestEvent)

  groupMeetings: ->
    @meetings = @meetingGroupUtils.groupMeetings @ungroupedMeetings
    @newSuggestionsButtonVisible = false

  switchTab: (tab) =>
    @showUpcoming = tab == "upcoming"
    @location.search("tab", tab)

  confirmHideSuggested: (meeting, onConfirm, onCancel) =>
    @confirmDialog = {
      title: "Hide this event?"
      message: "This meeting will be permanently hidden from your timeline."
      buttonConfirmCallback: =>
        @hideSuggested(meeting)

        if onConfirm?
          onConfirm()

      buttonConfirmCaption: "Hide"
      buttonCancelCallback: =>
        @confirmDialog = null

        if onCancel?
          onCancel()

      buttonCancelCaption: "Cancel"
    }

class MeetingShowCtrl extends MeetingBaseCtrl

  constructor: ->
    super
    @meetingId = @viewParams.get("meetingId")
    @meeting = @meetingService.getMeeting()

    @uploadProgress = null
    @participant = null
    @isManager = false
    @isRsvpRequired = false
    @meetingDataNotAvailable = true
    @removedMaterials = []

    @_loadShowView(@meeting)

    @_initMessageListener()
    @_setLayout()

  ################
  # PRIVATE
  ################

  _initMessageListener: ->

    # Enable back button functionality meeting#edit
    @scope.$on('$routeUpdate', =>
      @meeting = @meetingService.getMeeting()
    )

  _initMeetmeRequest: (meeting) ->
    if meeting.matchmaking_accepted == 0
      @meetmeState = 'initial'
    else
      @meetmeState = null

  _initParticipant: (meeting) ->
    @participant = @participantService.getParticipant(@userRoute.id, meeting.participants)

    @isManager = @participantService.isManager(@participant)
    @isRsvpRequired = @participantService.isRsvpRequired(@participant)
    @hasLeftScheduling = @participantService.hasLeftScheduling(@participant)

  _initInvitationButtonVisibility: ->
    @sendInvitationsButtonVisible = @meeting.participants?.length > 1 && @meeting.is_draft && @isManager

  _initParticipantListRsvpPropertyName: ->
    @rsvpPropertyName = if @schedulingStarted then 'has_answered_current_scheduling' else 'rsvp_status'

  _setMeeting: (meeting) ->
    @meeting = meeting

    @schedulingStarted = @meetingService.isSchedulingStarted(@meeting)
    @schedulingFailed = @meetingService.isSchedulingFailed(@meeting)

    @_initParticipant(@meeting)
    @_initInvitationButtonVisibility()
    @_initParticipantListRsvpPropertyName()

    @meetingService.setMeeting(@meeting)

  _unsetMeeting: ->
    @meeting = null

  _loadShowView: (meeting) ->
    @meetingLoaded = false
    @_initMeetmeRequest(meeting)
    @_setMeeting(meeting)

    @_reloadMeeting(meeting)

  _reloadMeeting: (meeting) ->
    @loading = true
    @delayedSpinner = true

    @setSelectedIndex(null)

    @meetingService.fetchMeeting(@meetingId, { image_size: @appConfig.thumbnail.small }).then(
      (data) =>
        @_setMeeting(data)
        @meetingLoaded = true

        @_setLayout()

      (failure) =>
        @log.error "[meeting#show] Load error:", failure
        @error = @errorHandlerService.handle failure
        @reloadRequired = true
        @accessDenied = failure?.error?.code == 403

    ).finally(
      =>
        @loading = false
    )

  _updateParticipantList: ->
    @participantService.fetchParticipantList(@meeting.id, { image_size: @appConfig.thumbnail.small } ).then(
      (data) =>
        @log.debug "participant list updated", data

        @meeting.participants = data

      (failure) =>
        @log.warn "participant update failed", failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure
    )

  _saveMeetmeConfimation: ->
    @meeting.put().then(
      (data) =>
        @_setLayout()
        @meetmeState = null
        @_setMeeting(data)
      (failure) =>
        @log.warn "Error accepting meet me request", failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure
    )

  _sendInvitations: (requireRsvp) ->
    @confirmDialog = null
    @btnWorking = "sendInvitations"

    @participantService.sendInvitationsToDraftParticipants(@meetingId, { require_rsvp: requireRsvp }).then(
      (data) =>
        @log.debug "Draft participants invited successfully", data

        @_reloadMeeting()

      (failure) =>
        @log.error "Failed to send invites", failure
        @error = @errorHandlerService.handle(failure)

    ).finally(
      =>
        @btnWorking = null
    )

  _setLayout: ->
    title = "Meeting"

    if @meetingService.isRemoved(@meeting)
      title = "Meeting removed"

    if !@meetingService.isRemoved(@meeting) && @meetingLoaded
      openControls = {
        imagePath: "images/more_13x13.svg"
        onClick: =>
          @_openMeetingControls()
      }

    @navigationBarService.update
      title: title
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.buttonToPath("/#{@tab}") else null
        right: openControls

  _setMeetMeButtons: ->
    backButton = {
      title: "Back"
      onClick: =>
        @rootScope.$broadcast("blurInput")
        @scope.$apply => @meetmeState = 'initial'
        @_setLayout()
    }

    @navigationBarService.update
      buttons:
        left: backButton

  _openEdit: (target) ->
    @viewParams.set({ fromReview: null })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/edit/#{target}")

  _openMeetingControls: ->
    @location.path("/#{@tab}/meeting/#{@meeting.id}/controls")

  #################
  # PUBLIC
  #################

  getBackgroundImageUrl: ( meeting ) ->
    @meetingService.getBackgroundImageUrl( meeting )

  isUpcoming: ->
    return @dateHelper.isEpochInFuture(@meeting.begin_epoch)

  isMaterialEmpty: (materialClass) ->
    return @meeting["#{materialClass}_html"].length == 0

  openParticipants: ->
    breadcrumb = encodeURIComponent(@meeting.title_value)

    isDraft = @meeting.is_draft == 1

    @viewParams.set({
      breadcrumb: breadcrumb
    })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/participants")


  openMaterial: (material) ->
    breadcrumb = encodeURIComponent(@meeting.title_value)

    @viewParams.set({
      breadcrumb: breadcrumb
      materialClass: material.material_class
    })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/material/#{material.id}")

  sendInvitations: ->
    if @isUpcoming()
      @confirmDialog = {
        title: "Require rsvp?"
        message: "Do you wish to request rsvp from participants?"
        buttonConfirmCallback: =>
          @_sendInvitations(true)
        buttonConfirmCaption: "Yes"
        buttonCancelCallback: =>
          @_sendInvitations(false)
        buttonCancelCaption: "No"
      }

    else
      @_sendInvitations(false)

  openScheduling: ->
    @location.path("/timeline/meeting/#{@meeting.id}/scheduling")

  openSwipeToMeet: ->
    @viewParams.set({ menuVisible: true })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/scheduling/#{@meeting.current_scheduling_id}")

  openSchedulingLog: ->
    @viewParams.set({
      showCloseButton: false
      showProvideAvailabilityButton: @meeting.current_scheduling.organizer_swiping_required
    })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/scheduling/#{@meeting.current_scheduling_id}/log")

  handleError: ->
    @error = null

    if @accessDenied
      @window.history.back()
      return

    if @reloadRequired
      @_setLayout()
      @_reloadMeeting(@meeting)

  edit: (target) ->
    return unless @isManager

    if target == "date" && @meeting.current_scheduling_id != 0
      @openSchedulingLog()

    else
      @_openEdit(target)

  updateRsvpStatus: (rsvpStatus) ->
    @rsvpBtnWorking = rsvpStatus

    @participantService.updateRsvpStatus(@participant.id, rsvpStatus).then(
      (data) =>
        @_updateParticipantList()
        @isRsvpRequired = false
        @rsvpBtnWorking = null

      (failure) =>
        @log.warn failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure
        @rsvpBtnWorking = null
    )

  openUrl: (url, type) ->
    appErrorCode = if type == "skype" then @errorHandlerService.SKYPE_OPEN_FAILED else @errorHandlerService.APP_OPEN_FAILED

    @mtnURL.open(url, null, "_blank").then(
      =>
        @log.debug "URL opened successfully"
      =>
        @error = @errorHandlerService.handleAppError appErrorCode
    )

  acceptMeetmeRequest: ->
    @log.debug "accept meet me"
    @meetmeState = 'accept'
    @_setMeetMeButtons()

  declineMeetmerequest: ->
    @log.debug "decline meet me"
    @meetmeState = 'decline'
    @_setMeetMeButtons()

  editMeetmeRequest: ->
    @meetMeBtnWorking = "edit"
    @meeting.matchmaking_accepted = 1

    @_saveMeetmeConfimation().finally(
      =>
        @meetMeBtnWorking = null
    )

  sendMeetmeConfirmation: ->
    @meetMeBtnWorking = "send"
    @meeting.matchmaking_accepted = 1

    @_saveMeetmeConfimation().then(
      (data) =>
        @sendInvitations()
    ).finally(
      =>
        @meetMeBtnWorking = null
    )

  sendMeetmeDeclination: ->
    @meetMeBtnWorking = "decline"

    @meeting.post("matchmaking_decline", {decline_message: @meetmeDeclination}).then(
      (data) =>
        @meetmeDeclination = null
        @jsonMsgChannel.publish JSON.stringify(
          event: "removeTimelineMeeting",
          id: @meeting.id
        )

        @window.history.back()

      (failure) =>
        @log.warn "Error declining", failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure
    ).finally(
      =>
        @meetMeBtnWorking = null
    )

  removeMaterial: (material) ->
    @removedMaterials.push(material)

    @materialService.removeMaterial(material.id).then(
      (data) =>
        @log.debug "Material removed successfully", data

        @setSelectedIndex(null)

      (failure) =>
        @log.error "Material remove failed", failure
        @error = @errorHandlerService.handle(failure)

        @removedMaterials.pop()
    )

  removeMaterialEnabled: (material) ->
    material.creator_id == @sessionService.getUserId() || @isManager

  setSelectedIndex: (index) ->
    @selectedIndex = index

class MeetingEditCtrl extends MeetingBaseCtrl

  constructor: ->
    super

    @editing = @viewParams.get("editing")
    @fromReview =  @viewParams.get("fromReview")

    @tinymceConf = {
      plugins: [ "autolink textcolor" ]
      menubar: false
      toolbar: false
      statusbar: false
    }

    @meeting = @meetingService.getMeeting()
    @_setMeeting()

    @_setEditButtons()

  #################
  # PRIVATE
  #################

  _setEditButtons: ->
    @navigationBarService.update(title: "Meeting")

    cancelButton = {
      title: "Cancel"
      onClick: =>
        @rootScope.$broadcast("blurInput")
        @cancelEdit()
    }

    saveButton = {
      title: "Done"
      onClick: =>
        @rootScope.$broadcast("blurInput")
        @confirmEdit()

        if !@scope.$$phase
          @scope.$apply()
    }

    @navigationBarService.update
      buttons:
        left: cancelButton
        right: if @deviceUtils.platform() == "ios" then saveButton

    if @fromReview
      @navigationBarService.hideMenu()

  _setEditCommunicationToolButtons: ->
    backButton = {
      title: "Back"
      onClick: =>
        @selectCommunicationToolType(@meeting.online_conferencing_option)
    }

    @navigationBarService.update
      SPAButtonHidden: true
      buttons:
        left: backButton

    if @fromReview
      @navigationBarService.hideMenu()

  _setPristine: ->
    @meetingPristine = angular.copy(@meeting)

  _revert: ->
    @meetingService.setMeeting(@meetingPristine)
    @meetingPristine = null

  _setMeeting: ->
    @dateUnset = @dateHelper.isEpochUnset(@meeting.begin_epoch)

    @_setPristine()
    @_setDefaultEpoch()

    if @editing == "communicationtool" && (!@meeting.online_conferencing_option? || @meeting.online_conferencing_option == "")
      @log.debug "communication tool not set"
      @toolSelectVisible = true

  _update: ->
    if @meeting.id?
      @loading = true
      @delayedSpinner = false

      @meeting.put().then(
        (data) =>
          @log.debug "Success updating", data

          if @editing == "communicationtool" && @meeting.online_conferencing_option == "lync"
            @removeTinyMCE("lync_copypaste")

          @meetingService.setMeeting(data)

          @editing = null

          @window.history.back()

        (failure) =>
          @log.warn "Error updating", failure
          @error = @errorHandlerService.handle failure
      ).finally(
        =>
          @loading = false
      )

    else
      @meetingService.setMeeting(@meeting)
      @window.history.back()

  _setDefaultEpoch: ->
    if @editing == "date" && @dateHelper.isEpochUnset(@meeting.begin_epoch)
      @meeting.begin_epoch = @dateHelper.defaultNewMeetingBeginDate()
      @meeting.end_epoch = @dateHelper.defaultNewMeetingEndDate(@meeting.begin_epoch)

  #################
  # PUBLIC
  #################

  handleError: ->
    @error = null

  isPro: ->
    return @currentUserService.isPro(@user)

  isUpcoming: ->
    return @dateHelper.isEpochInFuture(@meeting.begin_epoch)

  openStartTrialModal: ->
    @location.path("/#{@tab}/starttrial")

  openScheduling: ->
    @location.path("/timeline/meeting/#{@meeting.id}/scheduling")

  cancelEdit: ->
    @_revert()

    @window.history.back()

  editCommunicationToolType: ->
    if @meeting.online_conferencing_option == "lync"
      @removeTinyMCE("lync_copypaste")

    @toolSelectVisible = true
    @_setEditCommunicationToolButtons()

  selectCommunicationToolType: (tool) ->
    if !@isPro() && (tool == "hangout" || tool == "lync" || tool == "custom")
      @openStartTrialModal()

    else if tool == ""
      @meeting.online_conferencing_option = tool
      @_update()

    else

      # Prefill skype account if online conferencing data doesn't already have a skype account set
      if tool == "skype" &&
         (!@meeting.online_conferencing_data?.skype_account? ||
         @meeting.online_conferencing_data.skype_account == "")

        if !@meeting.online_conferencing_data?
          @meeting.online_conferencing_data = {}

        @meeting.online_conferencing_data.skype_account = @user.skype

      @_setEditButtons()
      @toolSelectVisible = false
      @meeting.online_conferencing_option = tool

  confirmEdit: ->
    if @editing == "communicationtool" && @meeting.online_conferencing_option == "lync"
      if @meeting.online_conferencing_data.lync_mode == "sip" && !@communicationtool.$valid
        @error = @errorHandlerService.handleAppError(@errorHandlerService.INVALID_FORM)
        return

      else
       @meeting.online_conferencing_data.lync_copypaste = tinyMCE.get("lync_copypaste").getContent()

    if @editing == "date" && @isUpcoming() && @meeting.participants?.length > 1 && !@meeting.is_draft
      @confirmDialog = {
        title: "Meeting time changed"
        message: "Ask participants to RSVP again?"
        buttonConfirmCallback: => @onDateEditConfirm(true)
        buttonConfirmCaption: "Yes"
        buttonCancelCallback: => @onDateEditConfirm(false)
        buttonCancelCaption: "No"
      }
    else
      @_update()

  onDateEditConfirm: (requireRsvpAgain) ->
    if requireRsvpAgain
      @meeting.require_rsvp_again = 1

    @confirmDialog = null
    @_update()

  openSchedulingWebDiagram: (id) ->
    OpenWindow = window.open("wsd.html", "mywin", "")

    @meeting.one("schedulings", id).one("flow").get().then(
      (data) =>
        output = data
        OpenWindow.dataFromParent = output
        OpenWindow.init()
    )

class MeetingControlsCtrl extends MeetingBaseCtrl

  constructor: ->
    super

    @meetingId = @viewParams.get("meetingId")
    @meeting = @meetingService.getMeeting()

    @wisdom = @meeting.created_epoch % 7;

    if @meeting.meetingDataNotAvailable
      @_fetchMeeting()
    else
      @_setMeeting(@meeting)

    @_setLayout()

  #################
  # PRIVATE
  #################

  _setLayout: ->
    @navigationBarService.update
      title: "Meeting controls"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _setUploadButtons: ->
    cancelButton = {
      title: "Cancel upload"
      onClick: =>
        @_cancelUpload()
    }

    @navigationBarService.update
      buttons:
        right: cancelButton # Cordova photo library's cancel button is also on the right.

    if @deviceUtils.platform() == "android"
      @navigationBarService.hideMenu()

  _fetchMeeting: ->
    @loading = true
    @delayedSpinner = true

    @meetingService.fetchMeeting(@meetingId, { image_size: @appConfig.thumbnail.small }).then(
      (data) =>

        @_setMeeting(data)

      (failure) =>
        @log.error "[meeting#show] Load error:", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _setMeeting: (meeting) ->
    @meeting = meeting

    @schedulingStarted = @meetingService.isSchedulingStarted(@meeting)
    @schedulingFailed = @meetingService.isSchedulingFailed(@meeting)

    @_initParticipant(@meeting)

  _initParticipant: (meeting) ->
    @participant = @participantService.getParticipant(@user.id, meeting.participants)

    @isManager = @participantService.isManager(@participant)
    @hasLeftScheduling = @participantService.hasLeftScheduling(@participant)

  _cancelUpload: ->
    @materialService.abortAddPhoto()

    @_setLayout()

  _removeMeeting: ->
    @btnWorking = "removingMeeting"
    @confirmDialog = null

    @meeting.remove().then(
      (data) =>
        @jsonMsgChannel.publish JSON.stringify(
          event: "removeTimelineMeeting",
          id: @meeting.id
        )

        @location.path("/#{@tab}").replace()

      (failure) =>
        @log.debug "Removing meeting failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  _leaveMeeting: ->
    @btnWorking = "removingParticipant"

    @participantService.removeParticipant(@participant.id).then(
      (data) =>
        @log.debug "Participant removed successfully", data

        @location.path("/#{@tab}").replace()

      (failure) =>
        @log.error "Participant remove failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  #################
  # PUBLIC
  #################

  leaveScheduling: ->
    @viewParams.set({ menuVisible: true })
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@meeting.current_scheduling_id}/leave/confirm")

  confirmRemoveMeeting: ->
    @confirmDialog = {
      title: "Remove meeting?"
      message: "This meeting will be removed permanently. Are you sure?"
      buttonConfirmCallback: => @_removeMeeting()
      buttonConfirmCaption: "Remove"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  confirmLeaveMeeting: ->
    @confirmDialog = {
      title: "Leave meeting?"
      message: "Are you sure you want to remove yourself from this meeting? You need to be invited to access it again."
      buttonConfirmCallback: => @_leaveMeeting()
      buttonConfirmCaption: "Ok"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  addPhoto: ->
    @_setUploadButtons()

    @materialService.addPhoto(@appConfig.thumbnail.small).then(
      (data) =>
        @log.debug "Converting photo to material", data
        @meeting.post("materials", { upload_id: data.result.upload_id, material_name: "Uploaded photo" })

    ).then(
      (material) =>
        @log.debug "material successfully converted", material
        @window.history.back()

      (failure) =>
        @log.error "Failed to upload or convert photo into a meeting material", failure
        @error = @errorHandlerService.handle failure

      (progress) =>
        @uploadProgress = progress

    ).finally(
      =>
        @uploadProgress = null
        @_setLayout()
    )

  handleError: ->
    @error = null

meetingApp = angular.module 'meetingApp',
  [
    'appConfig'
    'meetingModule'
    'currentUserModule'
    'participantModule'
    'calendarModule'
    'suggestionModule'
    'pusherModule'
    'animations'
    'materialFilters'
    'meetingGroupUtils'
    'nativeUi'
    'partials'
    'dateHelper'
    'mtnProgress'
    'mtnFloatLabel'
    'mtnSwipeToReveal'
    'mtnMoveCursorToEnd'
    'mtnListFilters'
    'ngAnimate'
    'ui.tinymce'
    'react'
    'meetingComponents'
    'mtnUtils'
    'connectivity'
    'mtnURL'
  ]

meetingApp.controller("MeetingIndexCtrl", MeetingIndexCtrl)
meetingApp.controller("MeetingShowCtrl", MeetingShowCtrl)
meetingApp.controller("MeetingEditCtrl", MeetingEditCtrl)
meetingApp.controller("MeetingControlsCtrl", MeetingControlsCtrl)

