class SwipeToMeetBaseCtrl
  @$inject =
    [ "$scope"
      "$rootScope"
      "$log"
      "$location"
      "$window"
      "$q"
      "$http"
      "$filter"
      "$analytics"
      "appConfig"
      "jsonMsgChannel"
      "SessionRestangular"
      "errorHandlerService"
      "sessionService"
      "dateHelper"
      "schedulingService"
      "matchmakerService"
      "meetingService"
      "currentUserService"
      "participantService"
      "navigationBarService"
      "pusherService"
      "viewParams"
      "deviceUtils"
      "contactService"
      "LocalDataRestangular"
     ]

  constructor: (@scope
                @rootScope
                @log
                @location
                @window
                @q
                @http
                @filter
                @analytics
                @appConfig
                @msgChannel
                @SessionRestangular
                @errorHandlerService
                @sessionService
                @dateHelper
                @schedulingService
                @matchmakerService
                @meetingService
                @currentUserService
                @participantService
                @navigationBarService
                @pusherService
                @viewParams
                @deviceUtils
                @contactService
                @LocalDataRestangular) ->

    @location.search("utm_source", null).replace()

    @tab = @viewParams.get("tab")

    @meetingId = @viewParams.get("meetingId")
    @schedulingId = @viewParams.get("schedulingId")

    @participantMaxCountBeforeSummary = @appConfig.meeting.participants.maxCountBeforeSummary
    @userRoute = @currentUserService.getRoute()

  ############
  # PRIVATE
  ############

  _redirectToThankYouPage: (msgId) ->
    return @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/thanks/#{msgId}")

  _fetchMeeting: (meetingId) ->
    @meetingService.fetchMeeting(meetingId, { image_size: @appConfig.thumbnail.medium }).then(
      (data) =>
        @meeting = data
        @meetingService.setMeeting(@meeting)

        # List of participants without manager
        @participants = _.where(@meeting.participants, {"is_manager": "0" })
        @participant = _.find(@meeting.participants, {"user_id": @sessionService.getUserId() })
        @participant = @participantService.restangularizeElement(@participant)

        @hasLeftScheduling = @participantService.hasLeftScheduling(@participant)


      (failure) =>
        @log.error "Failed to load meeting", failure
        @error = @errorHandlerService.handle failure
    )

  _fetchScheduling: (meetingId, schedulingId) ->
    @schedulingService.fetchScheduling(meetingId, schedulingId).then(
      (data) =>
        @scheduling = data
        @schedulingService.setScheduling(@scheduling)

      (failure) =>
        @log.error "Failed to load scheduling", failure
        @error = @errorHandlerService.handle failure
    )

  _fetchOption: (meetingId, schedulingId, optionId) ->
    @schedulingService.fetchOption(meetingId, schedulingId, optionId).then(
      (data) =>
        @option = data

      (failure) =>
        @log.error "Failed to load scheduling", failure
        @error = @errorHandlerService.handle failure
    )

  _reloadUser: ->
    @currentUserService.reload({ image_size: @appConfig.thumbnail.medium }).then(
      (user) =>
        @user = user

      (failure) =>
        @log.error "Failed to load user data"
        @error = @errorHandlerService.handle failure
    )

  _initParticipants: ->
    @manager = @participantService.getManager(@meeting.participants)
    @isManager = @sessionService.getUserId() == @manager.user_id

    participant = @participantService.getParticipant(@userRoute.id, @meeting.participants)

    @isReSwipe = participant.has_answered_current_scheduling == 1

  ############
  # PUBLIC
  ############

  openMeeting: ->
    @location.path("/#{@tab}/meeting/#{@meetingId}")

  replaceWithMeeting: ->
    @location.path("/#{@tab}/meeting/#{@meetingId}").replace()

class SwipeToMeetLandingCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @isReSwipe = false

    @listClosed = true

    @_initLandingPage()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "Meeting request"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
    })

    if @viewParams.get("menuVisible") != "true"
      @navigationBarService.hideMenu()

  _initLandingPage: ->
    @loading = true
    @q.all([
      @_fetchMeeting(@meetingId)
      @_fetchScheduling(@meetingId, @schedulingId)
      @_reloadUser()
    ]).then(
      =>
        # meeting removed, redirect to meeting page
        if parseInt(@meeting.removed_epoch) != 0
          @replaceWithMeeting()
          return

        # scheduling was replaced, redirect to thank you page
        if @meeting.current_scheduling_id != 0 && @meeting.current_scheduling_id != @schedulingId
          @_redirectToThankYouPage(4).replace()
          return

        # scheduling time was found, redirect to thank you page
        if @meetingService.isSchedulingCompleted(@meeting, @scheduling)
          @_redirectToThankYouPage(2).replace()
          return

        # scheduling was canceled, redirect to thank you page
        if @meetingService.isSchedulingCanceled(@meeting, @scheduling)
          @_redirectToThankYouPage(5).replace()
          return

        # scheduling was failed, redirect to thank you page
        if @meetingService.isSchedulingFailed(@meeting, @scheduling)
          @_redirectToThankYouPage(3).replace()
          return

        @_fetchSchedulingOptions(@meetingId, @schedulingId)
    ).finally(
      =>
        @_initParticipants()
        @loading = false
    )

  # Start loading first options on landing page and pass them to suggestions page if load is successful
  _fetchSchedulingOptions: (meetingId, schedulingId)->
    @schedulingService.fetchNextOption(meetingId, schedulingId).then(
      (data) =>
        if data.option.no_suggestions_left == 1
          @_redirectToThankYouPage(3).replace()
          return

        @options = data
      (failure) =>
        @log.error "Failed to fetch options", failure
        @error = @errorHandlerService.handle failure
    )

  ############
  # PUBLIC
  ############

  getBackgroundImageUrl: ( meeting ) ->
    @meetingService.getBackgroundImageUrl( meeting )

  openSwipe: ->
    @viewParams.add("options", @options)
    @location.path("/#{@tab}/meeting/#{@meeting.id}/scheduling/#{@schedulingId}/suggestions")

  leaveScheduling: ->
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/leave/confirm")

  handleError: ->
    @error = null

    @_initLandingPage()

class SwipeToMeetShowCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @redirectToSchedulingThanks = false

    @isFirstSwipeAction = !localStorage.getItem("isFirstSwipeAction")?
    localStorage.setItem("isFirstSwipeAction", false)

    @DEBUG_MODE = @schedulingId == "debug"

    if @DEBUG_MODE
      @_initDebugCards()

    else
      @thankyouCardShown = false

      @meeting = @meetingService.getMeeting()

      if @meeting.meetingDataNotAvailable
        @_fetchMeeting(@meetingId)

      @_initPusher()
      @_initSchedulingOptions()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "Is this time suitable?"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _setDoneButton: ->
    doneButton = {
      title: "Done"
      onClick: =>
        @_redirectToThankYouPage(1)
    }

    @navigationBarService.update
      buttons:
        left: @navigationBarService.defaultBackButton()
        right: doneButton

  _initPusher: ->
    channelName = @appConfig.pusher.channelName + @sessionService.getUserId()
    eventName = "scheduling_time_found"
    pusherCallback = (data) =>
      @log.debug "schedulingId", @schedulingId
      @log.debug "scheduling_time_found", data
      @log.debug "data.scheduling_id == @schedulingId =", parseInt(data.scheduling_id) == parseInt(@schedulingId)
      if parseInt(data.scheduling_id) == parseInt(@schedulingId)
        @redirectToSchedulingThanks = true
        @error = @errorHandlerService.msg( "Time was found just now.", { title: "Awesome!" } )
        @scope.$apply()

    @pusherService.subscribeAndBind(channelName, eventName, pusherCallback)

    @scope.$on("$destroy",
      =>
        @pusherService.unbind(channelName, eventName, pusherCallback)
    )

  _initSchedulingOptions: ->
    @nextOptionQueryList = []

    @activeOption = "yes_option"
    @lastSelectedOption = "yes_option"

    options = @viewParams.get("options")

    # Skip loading initial options if options were loaded succesfully on landing page.
    if options?
      @cards = @_initCards(options)
    else
      @loading = true

      @schedulingService.fetchNextOption(@meetingId, @schedulingId).then(
        (data) =>
          @cards = @_initCards(data)

        (failure) =>
          @log.error "Failed to fetch options", failure

          # Redirect to thank you page if the error is "This scheduling is not running"
          if failure?.error?.code == 1
            @_redirectToThankYouPage(4)
          else
            @error = @errorHandlerService.handle failure

      ).finally(
        =>
          @loading = false
      )

  _refreshSchedulingOptions: (selectedOption) ->
    @lastSelectedOption = selectedOption

    currentCard = @cards[0]
    nextCard = @cards[1]

    answer = if selectedOption == "yes_option" then "yes" else "no"

    if currentCard[selectedOption].optionalCardVisible && answer == "no"
      @_redirectToThankYouPage(1)

    else
      if currentCard[selectedOption].optionalCardVisible && answer == "yes"
        @navigationBarService.show("Is this time suitable?")
        @_setDoneButton()

      # Send answer to the current suggestion.
      # After sending the answer, if there are no more suggestions left, redirect to the end of the world page.
      @_answerOption(currentCard[selectedOption].id, answer).then(
        (data) =>
          if nextCard[selectedOption].no_suggestions_left == 1
            @_redirectToThankYouPage(3)
            return
      )

      # If next card has not yet been received from the api,
      # save this query to a list and run it when next card's data is available
      if !nextCard[selectedOption]?.id?
        @nextOptionQueryList.push({
          parent: currentCard
          answer: answer
          selectedOption: selectedOption
        })

      # If next card is available, fetch next option right now
      else
        @_nextSchedulingOption(currentCard, nextCard, answer, selectedOption)

    if(nextCard[selectedOption]?.optionalCardVisible?)
      @navigationBarService.show("Continue swiping?")

    # Push empty card to the bottom of the stack and shift by 1
    @cards.push({})
    @cards.shift()

    if !@scope.$$phase
      @scope.$apply()

  _nextSchedulingOption: (currentCard, nextCard, answer, selectedOption) ->
    @_fetchNextSchedulingOption(nextCard, nextCard[selectedOption].id, currentCard[selectedOption].id, answer, selectedOption).then(
      (data) =>

        data.yes_option = @_initSurroundingCalendarEntries(data.yes_option)
        data.no_option = @_initSurroundingCalendarEntries(data.no_option)

        if (data.yes_option.optional || data.no_option.optional) && !@thankyouCardShown
          data = @_replaceNextWithThankYouCard(data)

        emptyCardIndex = @_findNextEmptyCard()

        # Replace next empty card with real data
        _.extend(@cards[emptyCardIndex], data)

        # If there's a query in list,
        # run it now with the received data
        if @nextOptionQueryList.length > 0
          q = @nextOptionQueryList.shift()
          @_nextSchedulingOption(q.parent, data, q.answer, q.selectedOption)

      (failure) =>
        @log.error "Failed to fetch next options", failure

        # Don't show error dialog if the error is "This scheduling is not running"
        if failure.error.code != 1
          @error = @errorHandlerService.handle failure
    )

  _answerOption: (optionId, answer) ->
    return @schedulingService.answerOption(@meetingId, @schedulingId, optionId, answer)

  _fetchNextSchedulingOption: (nextCard, optionId, parentOptionId, parentAnswer, selectedOption) ->
    if !nextCard[selectedOption].optionalCardVisible
      return @schedulingService.fetchNextOptions(@meetingId, @schedulingId, optionId, parentOptionId, parentAnswer)

    # Return temp card wrapped in a promise if thank you card is visible
    deferred = @q.defer()
    deferred.resolve @tempCard
    return deferred.promise

  _findNextEmptyCard: ->
    index = _.findIndex(@cards
      (card) ->
        return !card.yes_option? && !card.no_option?
    )

    return index

  _replaceNextWithThankYouCard: (data) ->
    # Save the real data to a temp card
    @tempCard = angular.copy data

    @thankyouCardShown = true

    if data.yes_option.optional
      data.yes_option.optionalCardVisible = true

    if data.no_option.optional
      data.no_option.optionalCardVisible = true

    return data

  _initCards: (cards) ->

    if cards.option.no_suggestions_left == 1
      @_redirectToThankYouPage(3)
      return

    cards.option = @_initSurroundingCalendarEntries(cards.option)
    cards.yes_option = @_initSurroundingCalendarEntries(cards.yes_option)
    cards.no_option = @_initSurroundingCalendarEntries(cards.no_option)

    return [
      {
        yes_option: cards.option
        no_option: cards.option
      }
      {
        yes_option: cards.yes_option
        no_option: cards.no_option
      }
      {}
    ]

  _initSurroundingCalendarEntries: (option) ->
    if option? && option.user_calendar_entries?
      option.previousCalendarEntry = @_getPreviousCalendarEntry(option.user_calendar_entries.before)
      option.nextCalendarEntry = @_getPreviousCalendarEntry(option.user_calendar_entries.after)

    return option

  _getPreviousCalendarEntry: (previousEntries) ->
    return _.last(previousEntries)

  _getNextCalendarEntry: (nextEntries) ->
    return _.first(previousEntries)

  _initDebugCards: ->
    @meeting = {
      title_value: "Company Board meeting"
    }

    @activeOption = "yes_option"
    @lastSelectedOption = "yes_option"

    @http.get('/data/swipesuggestions.json').then(
      (res) =>
        _.each(res.data, (option) =>
          option.yes_option = @_initSurroundingCalendarEntries(option.yes_option)
          option.no_option = @_initSurroundingCalendarEntries(option.no_option)
        )
        @allDebugCards = res.data
        @cards = @allDebugCards.splice(0,3)
    )

  _refreshDebugSchedulingOptions: (selectedOption) ->
    oldCard = @cards.shift()
    @cards.push(@allDebugCards.shift())
    @allDebugCards.push(oldCard)

    if !@scope.$$phase
      @scope.$apply()

  ############
  # PUBLIC
  ############

  openCalendarConnect: ->
    # Remove cached options to force refresh calendar data
    @viewParams.add("options", null)
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/suggestions/selectsources")

  openInfo: ->
    currentCard = @cards[0][@lastSelectedOption]
    @viewParams.add("option", currentCard)
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/suggestions/info/#{currentCard.id}")

  setActiveOption: (option) ->
    @activeOption = option
    @scope.$apply()


  firstSwipeDialogConfirm: (yesAnswer) ->
    @confirmDialog = null

    if yesAnswer
      @acceptBtn()
    else
      @rejectBtn()

  firstSwipeDialogCancel: ->
    @confirmDialog = null
    @cancelSwipe()

  showFirstSwipeDialog: (yesAnswer, fromSwipe) =>
    @isFirstSwipeAction = false

    title = if yesAnswer then "Accept suggestion?" else "Decline suggestion?"
    confirmBtn = if yesAnswer then "Accept" else "Decline"

    message = ""

    if  yesAnswer &&  fromSwipe
      message = "Swiping right marks this suggestion suitable for you. Answers are permanent."

    if  yesAnswer && !fromSwipe
      message = "Tapping yes marks this suggestion suitable for you. Answers are permanent."

    if !yesAnswer &&  fromSwipe
      message = "Swiping left marks this suggestion unsuitable for you. Answers are permanent."

    if !yesAnswer && !fromSwipe
      message = "Tapping no marks this suggestion unsuitable for you. Answers are permanent."

    @confirmDialog = {
      title: title
      message: message
      buttonConfirmCallback: => @firstSwipeDialogConfirm(yesAnswer)
      buttonConfirmCaption: confirmBtn
      buttonCancelCallback: => @firstSwipeDialogCancel()
      buttonCancelCaption: "Cancel"
    }

    return

  cancelSwipe: ->
    @msgChannel.publish JSON.stringify(
      event: "cancelSwipe"
    )

  acceptBtn: ->
    if @isFirstSwipeAction
      @showFirstSwipeDialog(true, false)
    else
      @msgChannel.publish JSON.stringify(
        event: "swipeYes"
        optionId: @cards[0].yes_option.id
      )
      @accept()

  rejectBtn: ->
    if @isFirstSwipeAction
      @showFirstSwipeDialog(false, false)
    else
      @msgChannel.publish JSON.stringify(
        event: "swipeNo",
        optionId: @cards[0].yes_option.id
      )
      @reject()

  accept: ->
    @analytics.eventTrack("Suggestion accepted", {  Category: "SwipeToMeet" })

    if @DEBUG_MODE
      @_refreshDebugSchedulingOptions("yes_option")
    else
      @_refreshSchedulingOptions("yes_option")

  reject: ->
    @analytics.eventTrack("Suggestion rejected", {  Category: "SwipeToMeet" })

    if @DEBUG_MODE
      @_refreshDebugSchedulingOptions("no_option")
    else
      @_refreshSchedulingOptions("no_option")

  isCalendarEntryTooLong: (calendarEntry) ->
    return false unless calendarEntry?
    return @dateHelper.isDurationOverADay(calendarEntry.begin_epoch, calendarEntry.end_epoch)

  handleError: ->
    @error = null
    if @redirectToSchedulingThanks
      @_redirectToThankYouPage(2)
    else
      @_initSchedulingOptions()

class SwipeToMeetInfoCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @optionId = @viewParams.get("optionId")
    @user = @currentUserService.get()

    @_initInfoPageData()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "Suggestion details"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _initInfoPageData: ->
    @meeting = @meetingService.getMeeting()
    @scheduling = @schedulingService.getScheduling()
    @option = @viewParams.get("option")

    if @meeting.meetingDataNotAvailable ||
       _.isEmpty(@scheduling) ||
       !@option?

      @loading = true

      @q.all([
        @_fetchMeeting(@meetingId)
        @_fetchScheduling(@meetingId, @schedulingId)
        @_fetchOption(@meetingId, @schedulingId, @optionId)
        @_reloadUser()
      ]).finally(
        =>
          @userTimezone = jstz.determine().name()
          @organizerTimezone = @scheduling.time_zone

          @_initCalendarCount()
          @_initTimespan()
          @_initParticipantsAndAgenda()

          @loading = false
      )

    else
      @userTimezone = jstz.determine().name()
      @organizerTimezone = @scheduling.time_zone

      @_initCalendarCount()
      @_initTimespan()
      @_initParticipantsAndAgenda()

  _initParticipantsAndAgenda: ->
    @_initParticipants()
    @agenda = _.find(@meeting.materials, (material) -> material.material_class == 'agenda')

  _initTimespan: ->
    if @scheduling.available_timespans[0].end?
      @timespanEnd = @scheduling.available_timespans[0].end - @dateHelper.oneDayInSeconds

    @oneDaySpan = @scheduling.available_timespans[0].start == @timespanEnd

  _initCalendarCount: ->
    @enabledCalendarsCount = _.keys(@user.source_settings.enabled).length
    @totalCalendarsCount = _.keys(@user.source_settings.disabled).length + @enabledCalendarsCount

  ############
  # PUBLIC
  ############

  openParticipants: ->
    breadcrumb = encodeURIComponent(@meeting.title_value)
    @viewParams.set({ isDraft: false, breadcrumb: breadcrumb, isManager: false, overrideBackButton: true })
    @location.path("/#{@tab}/meeting/#{@meetingId}/participants")

  openMaterial: (material) ->
    breadcrumb = encodeURIComponent(@meeting.title_value)

    @viewParams.set({
      breadcrumb: breadcrumb
      isManager: false
      overrideBackButton: true
      materialClass: material.material_class
    })
    @location.path("/#{@tab}/meeting/#{@meeting.id}/material/#{material.id}")


  openCalendarSetting: ->
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/suggestions/selectsources")

  formatTimezone: (timezone) ->
    return unless timezone?
    return @dateHelper.formatTimezone(timezone)

  handleError: ->
    @error = null

    @_initInfoPageData()

class SwipeToMeetThanksCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @thanksMsg = @viewParams.get("thanksMsg")

    @user = @currentUserService.get()
    @newUser = @currentUserService.isNewUser(@user)

    @emailParticipant = @user.phone == ""

    @loading = true
    @_fetchMeeting(@meetingId).then(
      =>
        participant = @participantService.getParticipant(@user.id, @meeting.participants)
        @isManager = @participantService.isManager(participant)

    ).finally(
      =>
        @loading = false
    )

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    if @viewParams.get("showCloseButton") == "true"
      closeButton = {
        title: "Close"
        onClick: =>
          @location.path("/scheduling")
      }

    @navigationBarService.update({
      title: "SwipeToMeet"
      buttons:
        left: if !closeButton? then @navigationBarService.buttonToPath("/#{@tab}/meeting/#{@meetingId}") else null
        right: closeButton
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _confirmPhone: (phone) ->
    @currentUserService.confirmPhone(phone).then(
      (data) =>
        # Confirm phone is called only when phone number already exists,
        # so this success callback should never be reached.
        @log.debug "Confirm phone success", data

      (failure) =>
        if failure?.error?.code == 1
          @log.debug "Existing phone given, PIN code sent to number", failure

          @viewParams.set({
            phone: @user.primary_phone
          })
          @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/confirmPhone")

        else
          @log.warn "Failed email confirm: ", failure
          @error = @errorHandlerService.handle failure
    )

  ############
  # PUBLIC
  ############

  openSchedulingLog: ->
    @viewParams.set({
      showCloseButton: false
      showProvideAvailabilityButton: false
    })
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/log")

  showNotification: (notification) =>
    return notification.message.indexOf(@meeting.title_value) == 1

  continueSwiping: ->
    @window.history.back()

  signUp: ->
    @location.search({ meetingId: @meetingId, schedulingId: @schedulingId, msgId: @thanksMsg }).path("/signup")

  checkPhone: ->
    @formattedPhone = @contactService.formatPhone(@user.primary_phone, "null")

    if !@formattedPhone.valid
      @viewParams.set({
        phone: @formattedPhone.e164
      })
      @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/countryCode")
    else
      @submitPhone()

  submitPhone: ->
    @btnWorking = "sending"

    @user.primary_phone = @formattedPhone.e164

    @currentUserService.update(@user).then(
      (data) =>
        @log.debug "Saved user data", data
        @viewParams.set({
          phone: @user.primary_phone
        })
        @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/appDownloadGuide")

      (failure) =>
       if failure?.error?.code == 504
          @log.warn "User already exists: ", failure
          @_confirmPhone(@user.primary_phone)

        else
          @log.error "Failed to update user", failure
          @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  handleError: ->
    @error = null

    @loading = true
    @_fetchMeeting(@meetingId).finally(
      =>
        @loading = false
    )

class SwipeToMeetCountryCodeCtrl extends SwipeToMeetThanksCtrl

  constructor: ->
    super

    @phone = @viewParams.get("phone")

    if !@phone?
      @window.history.back()

    @formattedPhone = @contactService.formatPhone(@phone, "null")

    @_fetchCountryCodes()
    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    @navigationBarService.show()

    @navigationBarService.update({
      title: "Check your number"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    @navigationBarService.hideMenu()

  _fetchCountryCodes: ->
    @LocalDataRestangular.all("countrycodes").getList().then(
      (data) =>
        @countryCodes = data
    )

  ################
  # PUBLIC
  ################

  validatePhone: ->
    @formattedPhone = @contactService.formatPhone(@phone, @countryCode.id)

class SwipeToMeetConfirmPhoneCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @phone = @viewParams.get("phone")

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "SwipeToMeet"
      buttons:
        left: @navigationBarService.defaultBackButton()
        right: null
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  ################
  # PUBLIC
  ################

  verifyPin: ->
    @btnWorking = "signUp"
    @sessionService.signInWithPhonenumber(@phone, @pin).then(
      (data) =>
        @SessionRestangular.refreshDefaultHeaders()

        return @currentUserService.reload()

      (failure) =>
        @log.warn "Error signing in: ", failure
        @error = @errorHandlerService.handle failure

    ).then(
      (data) =>
        @viewParams.set({
          phone: @phone
        })
        @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/appDownloadGuide")

      (failure) =>
        @log.warn "Failed to reload user ", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  resendPin: ->
    @currentUserService.confirmPhone(@phone).then(
      (success) =>
        @log.debug "No existing user found"

      (failure) =>
        if failure?.error?.code == 1
          @log.debug "Existing email given, PIN code sent to email", failure
          @pinReRequested = true
    )

class SwipeToMeetAppDownloadGuideCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @phone = @viewParams.get("phone")

    if @phone?
      @_sendAppSms()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "App download"
      buttons:
        left: null
        right: null
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _sendAppSms: ->
    @currentUserService.getRoute().post("send_app_sms").then(
      (data) =>
        @log.debug "App download link sent successfully"

      (failure) =>
        @log.debug "Failed to send app download sms", failure
        @error = @errorHandlerService.handle failure
    )

  ############
  # PUBLIC
  ############

  resendSms: ->
    @_sendAppSms().then(
      (data) =>
        @log.debug "App download link sent successfully"
        @smsReRequested = true

      (failure) =>
        @log.debug "Failed to send app download sms", failure
        @error = @errorHandlerService.handle failure
    )

class SwipeToMeetConfirmLeaveCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @user = @currentUserService.get()
    @meeting = @meetingService.getMeeting()

    if @meeting.meetingDataNotAvailable
      @_fetchMeeting()
    else
      @_setMeeting(@meeting)

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "Delegate meeting?"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
        right: null
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _fetchMeeting: ->
    @loading = true

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
    @participant = @participantService.restangularizeElement(
      @participantService.getParticipant(@user.id, meeting.participants)
    )

    @hasLeftScheduling = @participantService.hasLeftScheduling(@participant)

  _disableScheduling: ->
    @btnWorking = "disableScheduling"

    @participantService.disableScheduling(@participant).then(
      (data) =>
        @log.debug "Participant removed from scheduling", data

        @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/leave")

      (failure) =>
        @log.error "Failed to remove participant from scheduling", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  ############
  # PUBLIC
  ############

  buttonYes: ->
    @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/leave/invitesubstitute")

  buttonNo: ->
    @_disableScheduling()

class SwipeToMeetInviteSubsituteCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @participants = []
    @user = @currentUserService.get()
    @userCountryId = @currentUserService.getUserPhoneCountryId(@user)

    @meeting = @meetingService.getMeeting()

    @contactPermissionTextVisible = !@contactService.getPermissionAsked()

    if @meeting.meetingDataNotAvailable
      @_fetchMeeting()
    else
      @_setMeeting(@meeting)

    @_getLatestContacts()
    @_initParticipantListWatcher()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    doneButton = {
      title: "Done"
      disabled: !@participants.length
      onClick: =>
        @_participantSelectDone()
    }

    @navigationBarService.update({
      title: "Choose contacts"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
        right: doneButton
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _initParticipantListWatcher: ->
    @scope.$watch(
      =>
        return @participants
      =>
        @_participantListChanged()
    , true)

  _fetchMeeting: ->
    @loading = true

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
    @participant = @participantService.restangularizeElement(
      @participantService.getParticipant(@user.id, meeting.participants)
    )

    @hasLeftScheduling = @participantService.hasLeftScheduling(@participant)

  _participantListChanged: ->
    @_setLayout()

  _saveLatestContacts: ->
    @contactService.setLatestContactsForUser(@user.id, @participants)

  _getLatestContacts: ->
    @latestContacts = @contactService.getLatestContacts()?[@user.id]

  _participantSelectDone: ->
    if @participants.length == 0
      @error = @errorHandlerService.handleAppError(@errorHandlerService.EMPTY_CONTACT_LIST)
      return

    @_saveLatestContacts()

    @_addParticipantAndLeaveScheduling()

  _addParticipantAndLeaveScheduling: (name, number) ->
    addParticipantPromises = []
    _.each(@participants, (participant) =>
      addParticipantPromises.push(@participantService.addParticipant(@meetingId, participant))
    )

    @q.all(addParticipantPromises).then(
      (data) =>
        @log.debug "Participants added successfully", data

        @_disableScheduling()

      (failure) =>
        @log.error "Participant adding failed", failure
        @error = @errorHandlerService.handle failure
    )

  _disableScheduling: ->
    @btnWorking = "disableScheduling"

    @participantService.disableScheduling(@participant).then(
      (data) =>
        @log.debug "Participant removed from scheduling", data

        @location.path("/#{@tab}/meeting/#{@meetingId}/scheduling/#{@schedulingId}/leave")

      (failure) =>
        @log.error "Failed to remove participant from scheduling", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

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

  handleError: ->
    @error = null

class SwipeToMeetLeaveCtrl extends SwipeToMeetBaseCtrl

  constructor: ->
    super

    @user = @currentUserService.get()
    @meeting = @meetingService.getMeeting()

    if @meeting.meetingDataNotAvailable
      @_fetchMeeting()
    else
      @_setMeeting(@meeting)

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "You left the scheduling"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null
        right: null
    })

    if !@viewParams.get("menuVisible")
      @navigationBarService.hideMenu()

  _fetchMeeting: ->
    @loading = true

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
    @participant = @participantService.restangularizeElement(
      @participantService.getParticipant(@user.id, meeting.participants)
    )

  _leaveMeeting: ->
    @confirmDialog = null
    @btnWorking = "removingParticipant"

    @participantService.removeParticipant(@participant.id).then(
      (data) =>
        @log.debug "Participant removed successfully", data

        @location.path("/#{@tab}")

      (failure) =>
        @log.error "Participant remove failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  ############
  # PUBLIC
  ############

  confirmLeaveMeeting: ->
    @confirmDialog = {
      title: "Leave meeting?"
      message: "Are you sure you want to remove yourself from this meeting? You need to be invited to access it again."
      buttonConfirmCallback: => @_leaveMeeting()
      buttonConfirmCaption: "Ok"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  handleError: ->
    @error = null

swipeToMeetApp = angular.module "swipeToMeetApp",
  [
    "ngAnimate"
    "appConfig"
    "SessionModel"
    "nativeUi"
    "dateHelper"
    "matchmakerModule"
    "meetingModule"
    "participantModule"
    "schedulingModule"
    "pusherModule"
    "mtnSwipeCard"
    "mtnFloatLabel"
    "mtnMomentModule"
    "partials"
    "mtnUtils"
    "contactModule"
    "mtnContactPicker"
  ]

swipeToMeetApp.controller("SwipeToMeetLandingCtrl", SwipeToMeetLandingCtrl)
swipeToMeetApp.controller("SwipeToMeetShowCtrl", SwipeToMeetShowCtrl)
swipeToMeetApp.controller("SwipeToMeetInfoCtrl", SwipeToMeetInfoCtrl)
swipeToMeetApp.controller("SwipeToMeetThanksCtrl", SwipeToMeetThanksCtrl)
swipeToMeetApp.controller("SwipeToMeetCountryCodeCtrl", SwipeToMeetCountryCodeCtrl)
swipeToMeetApp.controller("SwipeToMeetConfirmPhoneCtrl", SwipeToMeetConfirmPhoneCtrl)
swipeToMeetApp.controller("SwipeToMeetAppDownloadGuideCtrl", SwipeToMeetAppDownloadGuideCtrl)
swipeToMeetApp.controller("SwipeToMeetConfirmLeaveCtrl", SwipeToMeetConfirmLeaveCtrl)
swipeToMeetApp.controller("SwipeToMeetInviteSubsituteCtrl", SwipeToMeetInviteSubsituteCtrl)
swipeToMeetApp.controller("SwipeToMeetLeaveCtrl", SwipeToMeetLeaveCtrl)
