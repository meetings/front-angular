participantApp = angular.module 'participantApp', ['sessionModule']

class ParticipantBaseCtrl
  @$inject =
    [
      "$scope"
      "$rootScope"
      "$log"
      "$q"
      "$location"
      "$window"
      "$timeout"
      "appConfig"
      "SessionRestangular"
      "sessionService"
      "errorHandlerService"
      "participantService"
      "navigationBarService"
      "schedulingLogService"
      "meetingService"
      "dateHelper"
      "breadcrumb"
      "differenceFilter"
      "viewParams"
      "pusherService"
      "deviceUtils"
      "contactService"
      "currentUserService"
    ]

  constructor: ( @scope
                 @rootScope
                 @log
                 @q
                 @location
                 @window
                 @timeout
                 @appConfig
                 @SessionRestangular
                 @sessionService
                 @errorHandlerService
                 @participantService
                 @navigationBarService
                 @schedulingLogService
                 @meetingService
                 @dateHelper
                 @breadcrumb
                 @differenceFilter
                 @viewParams
                 @pusherService
                 @deviceUtils
                 @contactService
                 @currentUserService ) ->

    @tab = @viewParams.get("tab")
    @breadcrumb.set(@viewParams.get("breadcrumb"), @viewParams.get("breadcrumbClickable"))
    @overrideBackButton = @viewParams.get("overrideBackButton")
    @meetingId = @viewParams.get("meetingId")

  ############
  # PRIVATE
  ############

  _isUpcoming: (meeting) ->
    return @dateHelper.isEpochInFuture(meeting.begin_epoch)

  _isManager: (participants) ->
    userId = @sessionService.getUserId()
    participant = @participantService.getParticipant(userId, participants)
    return @participantService.isManager(participant)

  _fetchMeeting: ->
    @meetingService.fetchMeeting(@meetingId).then(
      (data) =>

        @_setMeeting(data)
        return data

      (failure) =>
        @log.error "Fetching meeting failed", failure
        @error = @errorHandlerService.handle failure
    )

  _setMeeting: (meeting) ->
    @meeting = meeting

    @isUpcoming = @_isUpcoming(meeting)
    @isDraft = meeting.is_draft == 1

    @schedulingId = meeting.current_scheduling_id
    @isSchedulingActive = @schedulingId? && @schedulingId != 0

  _resetError: ->
    @error = null

  ############
  # PUBLIC
  ############

  toggleRsvpRequired: ->
    @rsvpRequired = !@rsvpRequired

  setRsvpRequired: (rsvpRequired) ->
    @rsvpRequired = rsvpRequired

class ParticipantIndexCtrl extends ParticipantBaseCtrl

  constructor: ->
    super

    @_init()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    addButton = {
      imagePath: "images/add@2x.png"
      onClick: =>
        @_openNewPartcipant()
    }

    @navigationBarService.update
      title: "Participants"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
        right: addButton

  _openNewPartcipant: ->
    breadcrumb = encodeURIComponent(@breadcrumb.title)

    @viewParams.set({
      breadcrumb: breadcrumb
    })
    @location.path("/#{@tab}/meeting/#{@meetingId}/participants/add")

  _init: ->
    @loading = true
    @participants = []
    @removedParticipants = []

    @setSelectedIndex(null)

    initPromises = [
      @_fetchParticipantList()
      @_fetchMeeting()
    ]

    @q.all(initPromises).then(
      (data) =>
        @participants = data[0]

        @sendInvitationsVisible = @participants.length > 1 && @isDraft

        @isManager = @_isManager(@participants)

      (failure) =>
        @log.error "Failed loading participants", failure
        @error = @errorHandlerService.handle(failure)
    ).finally(
      =>
        @loading = false
    )

  _fetchParticipantList: ->
    return @participantService.fetchParticipantList(@meetingId, { image_size: @appConfig.thumbnail.medium } )

  _sendInvitations: (requireRsvp) ->
    @confirmDialog = null
    @btnWorking = "sendInvitations"

    @participantService.sendInvitationsToDraftParticipants(@meetingId, { require_rsvp: requireRsvp }).then(
      (data) =>
        @log.debug "Draft participants invited successfully", data

        @meeting.is_draft = 0
        @meetingService.setMeeting(@meeting)

        @window.history.back()

      (failure) =>
        @log.error "Failed to send invites", failure
        @error = @errorHandlerService.handle(failure)

    ).finally(
      =>
        @btnWorking = null
    )

  ############
  # PUBLIC
  ############

  openParticipant: (participantId) ->
    breadcrumb = encodeURIComponent(@breadcrumb.title)

    @viewParams.set({
      breadcrumb: breadcrumb
      overrideBackButton: @overrideBackButton
    })
    @location.path("/#{@tab}/meeting/#{@meetingId}/participants/#{participantId}")

  sendInvitations: ->
    if @isUpcoming
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

  handleError: ->
    @reload()

  reload: ->
    @_resetError()
    @_init()

  removeParticipant: (participant) ->
    @removedParticipants.push(participant)
    @participants = @differenceFilter(@participants, @removedParticipants)
    @sendInvitationsVisible = @participants.length > 1 && @isDraft

    @participantService.removeParticipant(participant.id).then(
      (data) =>
        @log.debug "Participant removed successfully", data

        @setSelectedIndex(null)

        @sendInvitationsVisible = @participants.length > 1 && @isDraft

      (failure) =>
        @log.error "Participant remove failed", failure
        @error = @errorHandlerService.handle failure

        @removedParticipants.pop()
        @participants = @differenceFilter(@participants, @removedParticipants)
        @sendInvitationsVisible = @participants.length > 1 && @isDraft
    )

  removeParticipantEnabled: (participant) ->
    return @isManager

  removeParticipantAllowed: (participant) ->
    return participant.user_id != @sessionService.getUserId()

  setSelectedIndex: (index) ->
    @selectedIndex = index


class ParticipantShowCtrl extends ParticipantBaseCtrl

  constructor: ->
    super

    @participantId = @viewParams.get("participantId")
    @schedulingId = @viewParams.get("schedulingId")

    @fullLog = false
    @logData = []

    @_init()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update
      title: "Participant"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _initPusher: ->
    channelName = @appConfig.pusher.channelName + @sessionService.getUserId()

    pusherNewLogEntryCallback = (data) =>
      if parseInt(data.scheduling_id) == parseInt(@schedulingId) && (@logData.length == 0 || data.entry_id >= _(@logData).pluck("id").last())
        @scope.$apply => @_fetchSchedulingLogWithMinEpoch()

    @pusherService.subscribeAndBind(channelName, "new_scheduling_log_entries", pusherNewLogEntryCallback)

    @scope.$on("$destroy",
      =>
        @pusherService.unbind(channelName, "new_scheduling_log_entries", pusherNewLogEntryCallback)
    )

  _init: ->
    @loading = true

    initPromises = [
      @_fetchParticipant()
      @_fetchMeeting()
    ]

    @q.all(initPromises).then(
      (data) =>
        @log.debug "[Participant] Fetching participant success", data

        @participant = data[0]

        @schedulingEnabled = @participant.scheduling_disabled == 0

        @isParticipantCurrentUser = @participant.user_id == @sessionService.getUserId()

        @isParticipantManager = @participantService.isManager(@participant)

        @isManager = @_isManager(@meeting.participants)

        if @isSchedulingActive
          @_initPusher()
          @_fetchSchedulingLog()

      (failure) =>
        @log.error "[Participant] Fetching participant failed", failure
        @error = @errorHandlerService.handle(failure)

    ).finally(
      =>
        @loading = false
    )

  _fetchParticipant: ->
    return @participantService.fetchParticipant(@participantId, { image_size: @appConfig.thumbnail.large })

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
    # Use only regular log messages
    logMessages = _.filter(logData, (entry) =>
      return entry.entry_type != "user_state_changed" &&
             entry.entry_type != "instruction_changed" &&
             (entry.data.user_id == @participant.user_id || entry.author_id == @participant.user_id)
    )
    @eventLog = @schedulingLogService.formatLogMessages(logMessages)

  _enableScheduling: ->
    @btnWorking = "enableScheduling"
    @participant.scheduling_disabled = 0
    @schedulingEnabled = true

    @participantService.enableScheduling(@participant).then(
      (data) =>
        @log.debug "Participant added to scheduling", data


      (failure) =>
        @log.error "Failed to add participant to scheduling", failure
        @error = @errorHandlerService.handle failure

        @participant.scheduling_disabled = 1
        @schedulingEnabled = false

    ).finally(
      =>
        @btnWorking = null
    )

  ############
  # PUBLIC
  ############

  toggleLogSize: ->
    @fullLog = !@fullLog

  resendSchedulingInvitation: ->
    @btnWorking = "resendingInvitation"

    @participantService.resendSchedulingInvitation(@participant).then(
      (data) =>
        @log.debug "Invitation sent successfully", data

        @invitationSent = true

      (failure) =>
        @log.error "Resending invitation failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  disableScheduling: ->
    @btnWorking = "disableScheduling"
    @participant.scheduling_disabled = 1
    @schedulingEnabled = false

    @participantService.disableScheduling(@participant).then(
      (data) =>
        @log.debug "Participant removed from scheduling", data
        @participant.scheduling_disabled_by_user_id = @sessionService.getUserId()

      (failure) =>
        @log.error "Failed to remove participant from scheduling", failure
        @error = @errorHandlerService.handle failure

        @participant.scheduling_disabled = 0
        @schedulingEnabled = true

    ).finally(
      =>
        @btnWorking = null
    )

  enableScheduling: ->
    if @participant.scheduling_disabled_by_user_id == @sessionService.getUserId()
      @_enableScheduling()
      return

    @confirmDialog = {
      title: "Are you sure?"
      message: "#{@participant.name} decided not to participate in this scheduling. Are you sure you want to reactivate the scheduling for #{@participant.name}?"
      buttonConfirmCallback: =>
        @_enableScheduling()
        @confirmDialog = null
      buttonConfirmCaption: "Activate"
      buttonCancelCallback: =>
        @schedulingEnabled = false
        @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  removeParticipant: ->
    @btnWorking = "removingParticipant"

    @participantService.removeParticipant(@participant.id).then(
      (data) =>
        @log.debug "Participant removed successfully", data

        @window.history.back()

      (failure) =>
        @log.error "Participant remove failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  toggleSchedulingEnabled: ->
    if !@schedulingEnabled
      @enableScheduling()

    else
      @disableScheduling()

  setSchedulingEnabled: (schedulingEnabled) ->
    if !@schedulingEnabled
      @enableScheduling()

    else
      @disableScheduling()

  handleError: ->
    @reload()

  reload: ->
    @_resetError()
    @_init()

class ParticipantNewCtrl extends ParticipantBaseCtrl

  constructor: ->
    super

    @contactPermissionTextVisible = !@contactService.getPermissionAsked()

    @participants = []
    @user = @currentUserService.get()
    @userCountryId = @currentUserService.getUserPhoneCountryId(@user)

    @delayedSpinner = false

    @_fetchMeeting()
    @_getLatestContacts()
    @_initParticipantListWatcher()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    saveButton = {
      title: "Done"
      disabled: !@participants.length
      onClick: =>
        @addParticipants()
    }

    @navigationBarService.update
      title: "Invite"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
        right:  saveButton


  _initParticipantListWatcher: ->
    @scope.$watch(
      =>
        return @participants
      =>
        @_participantListChanged()
    , true)

  _addParticipants: (requireRsvp) ->
    @loading = true

    addParticipantPromises = []
    _.each(@participants, (participant) =>

      participant.require_rsvp = requireRsvp

      addParticipantPromises.push(@participantService.addParticipant(@meetingId, participant))
    )

    @q.all(addParticipantPromises).then(
      (data) =>
        @log.debug "Participants added successfully", data

        @_saveLatestContacts()

        @window.history.back()

      (failure) =>
        @log.error "Participant adding failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _participantListChanged: ->
    @_setLayout()

  _saveLatestContacts: ->
    @contactService.setLatestContactsForUser(@user.id, @participants)

  _getLatestContacts: ->
    @latestContacts = @contactService.getLatestContacts()?[@user.id]

  ############
  # PUBLIC
  ############

  onAddParticipant: (participant, type) ->
    @log.debug "#{type} participant added", participant

    validatedParticipant = @contactService.isValidParticipant(@meeting.participants, participant, type, @user, @userCountryId)

    if validatedParticipant?.existingParticipant?
      @error = @errorHandlerService.handleAppError(@errorHandlerService.PHONENUMBER_EXISTS)

    else if validatedParticipant?.error?
      @error = validatedParticipant.error

    else
      @meeting.participants.push(participant)
      @participants.push(participant)

  onRemoveParticipant: (participant) ->
    @log.debug "participant removed", participant

    _.remove(@meeting.participants, participant)
    _.remove(@participants, participant)

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

  addParticipants: ->
    if @participants.length == 0
      @error = @errorHandlerService.handleAppError(@errorHandlerService.EMPTY_CONTACT_LIST)
      return

    if @isDraft || @isSchedulingActive
      @_addParticipants(false)

    else
      @confirmDialog = {
        title: "Require rsvp?"
        message: "Do you wish to request rsvp from participants?"
        buttonConfirmCallback: =>
          @_addParticipants(true)
        buttonConfirmCaption: "Yes"
        buttonCancelCallback: =>
          @_addParticipants(false)
        buttonCancelCaption: "No"
      }

  handleError: ->
    @error = null

participantApp = angular.module 'participantApp',
  [
    'appConfig'
    'ngAnimate'
    'partials'
    'participantModule'
    'schedulingLogModule'
    'meetingModule'
    'mtnFloatLabel'
    'mtnCheckbox'
    'nativeUi'
    'ngTagsInput'
    'mtnSwipeToReveal'
    'mtnListFilters'
    'mtnA'
    'pusherModule'
    'mtnUtils'
    'mtnContactPicker'
    'contactModule'
    'currentUserModule'
  ]

participantApp.controller 'ParticipantIndexCtrl', ParticipantIndexCtrl
participantApp.controller 'ParticipantShowCtrl', ParticipantShowCtrl
participantApp.controller 'ParticipantNewCtrl', ParticipantNewCtrl
