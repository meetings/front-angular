class MaterialBaseCtrl

  @$inject =
    [
      "$scope"
      "$rootScope"
      "$location"
      "$log"
      "$q"
      "$window"
      "$timeout"
      "$analytics"
      "appConfig"
      "SessionRestangular"
      "errorHandlerService"
      "sessionService"
      "meetingService"
      "navigationBarService"
      "breadcrumb"
      "materialService"
      "participantService"
      "differenceFilter"
      "viewParams"
      "dateHelper"
      "stringUtils"
      "mtnURL"
      "deviceUtils"
    ]

  constructor: (@scope
                @rootScope
                @location
                @log
                @q
                @window
                @timeout
                @analytics
                @appConfig
                @SessionRestangular
                @errorHandlerService
                @sessionService
                @meetingService
                @navigationBarService
                @breadcrumb
                @materialService
                @participantService
                @differenceFilter
                @viewParams
                @dateHelper
                @stringUtils
                @mtnURL
                @deviceUtils) ->

    @tab = @viewParams.get("tab")
    @breadcrumb.set(@viewParams.get("breadcrumb"), @viewParams.get("breadcrumbClickable"))

# Material editing can be done for existing meetings or in case of a new scheduling, a null meeting.
# When meeting is null the following special cases apply:
#   - @materialId is null
#   - Material is edited only in memory, no data is sent to the api
#   - Saving material edit sends an event to the scheduling to update initial_agenda property
#   - Comments are hidden
class MaterialShowCtrl extends MaterialBaseCtrl

  constructor: ->
    super

    @meeting = @meetingService.getMeeting()

    @meetingId = @viewParams.get("meetingId")
    @materialId = @viewParams.get("materialId")
    @materialClass = @viewParams.get("materialClass")
    @overrideBackButton = @viewParams.get("overrideBackButton")

    @isEditable = @materialClass == "agenda" || @materialClass == "action_points"

    @showComments = @tab != "scheduling"

    @removedComments = []

    @wasEdited = false

    @_initPlaceholder()

    if @materialId?
      @_initMaterial()
    else
      @_initEmptyMaterial()

    @_initMessageListener()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _setTitle: ->
    title = "Material"

    if @materialClass == "agenda"
      title = "Agenda"

    if @materialClass == "action_points"
      title = "Action points"

    @navigationBarService.show(title)

  _setLayout: ->
    @_setTitle()

    cancelButton = {
      title: "Cancel"
      onClick: =>

        @confirmCancel()
    }

    saveButton = {
      title: "Done"
      onClick: =>

        @done()
    }

    @navigationBarService.update
      buttons:
        left: cancelButton
        right: if @deviceUtils.platform() == "ios" then saveButton else null

  _closeMaterial: ->
    @window.history.back()

  _initMessageListener: ->
    @scope.$on('$destroy', =>
      @log.debug "[Material] destroyed, removing material lock"

      window.onbeforeunload = null

      if @editData?
        @cancelEdit()
    )

  _fetchMaterial: ->
    return @materialService.fetchMaterial(@materialId)

  _fetchComments: ->
    return @materialService.fetchComments(@materialId)

  _fetchMeeting: ->
    return @meetingService.fetchMeeting(@meetingId)

  _initMaterial: ->
    @loading = true

    @q.all([
      @_fetchMaterial()
      @_fetchComments()
      @_fetchMeeting()
    ]).then(
      (data) =>
        @log.debug "Init material success", data

        @material = data[0]
        @typeClass = @material.type_class
        @materialClass = @material.material_class
        @isEditable = @typeClass == "editabledocument"

        if @isEditable
          @material.content = @stringUtils.stripHtml(@material.content)
          @originalContent = @material.content

          if @material.content.length == 0
            @editMaterial()

        @comments = data[1]
        @meeting = data[2]

        @_initPlaceholder()

        @_setLayout()

      (failure) =>
        @log.error "Error initializing material view", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _initEmptyMaterial: ->
    # Ugly hack because autoGrow directive updates model too late :(
    @timeout =>
      @material = {
        content: @stringUtils.stripHtml(@meeting.initial_agenda)
      }
      @originalContent = @material.content
      @isEditable = true
      @scope.$apply()

    @timeout =>

      @editMaterial()
      @scope.$apply()

    , 300

  _initPlaceholder: ->
    switch @materialClass
      when "agenda"
        @materialPlaceholder = "Why are you meeting? Type in the agenda to share it with others."
      when "action_points"
        @materialPlaceholder = "Let others know what was the outcome of the meeting."
      else
        @materialPlaceholder = "Type in your custom notes."

  _updateScheduling: ->
    @meeting.initial_agenda = @material.content
    @meetingService.setMeeting(@meeting)

  _editStartSuccess: (data) ->
    @editData = data

  _continueEdit: ->
    return @materialService.continueMaterialEdit(@materialId).then(
      (data) =>
        @log.debug "Continued editing succesfully", data
        @_editStartSuccess(data)

      (failure) =>
        @log.error "Failed to continue interrupted editing", failure
        @error = @errorHandlerService.handle failure

        @rootScope.$broadcast("blurInput")
    )

  _openInExternal: ->
    @confirmDialog = null
    @mtnURL.open(@material.open_url, null, "_blank")

  ############
  # PUBLIC
  ############

  openMeeting: ->
    @meetingService.setMeeting(@meeting)
    @location.path("/#{@tab}/meeting/#{@meeting.id}")

  confirmCancel: ->
    if !@wasEdited
      @cancel()

    else
      @confirmDialog = {
        title: "Discard changes?"
        message: "Changes will be lost if you continue."
        buttonConfirmCallback: => @cancel()
        buttonConfirmCaption: "Continue"
        buttonCancelCallback: => @confirmDialog = null
        buttonCancelCaption: "Cancel"
      }

  confirmOpen: ->
    @confirmDialog = {
      title: "Open material?"
      message: "This material will be opened in your devices default browser."
      buttonConfirmCallback: => @_openInExternal()
      buttonConfirmCaption: "Ok"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  done: ->
    @rootScope.$broadcast("blurInput")

    @_updateScheduling()

    if @editData?
      @updateMaterial().then =>
        @_closeMaterial()
    else
      @_closeMaterial()

  cancel: ->
    @rootScope.$broadcast("blurInput")

    if @editData?
      @cancelEdit().then =>
        @_closeMaterial()
    else
      @_closeMaterial()

  cancelEdit: ->
    @materialService.cancelEditing(@editData.id).then(
      (data) =>
        @log.debug "Material lock removed", data
        @editData = null
    )

  materialChanged: ->
    return unless !@loading || @material.content == @originalContent

    @wasEdited = true

    window.onbeforeunload = () ->
      return "Changes will be lost if you continue."

  editMaterial: ->
    @rootScope.$broadcast("focusInput")
    # @wasEdited = true

    # Edit lock is not removed if textarea is just blurred
    if @materialId? && !@editData?
      @loading = true

      @materialService.getMaterialEditLock(@materialId).then(
        (data) =>
          @log.debug "Material lock received", data
          @_editStartSuccess(data)

        (failure) =>
          @log.error "Material locking failed, attempting to continue interrupted editing", failure

          @_continueEdit()

      ).finally(
        =>
          @loading = false
      )

  updateMaterial: ->
    @loading = true

    if @isEditable
      content = @stringUtils.stripHtml(@material.content)
      content = @stringUtils.lineBreakToBr(@material.content)
    else
      content = @material.content

    @materialService.updateMaterial(@materialId, @editData, content).then(
      (data) =>
        @log.debug "Material update success", data
        @editData = null

      (failure) =>
        @log.error "Error updating material", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  createComment: (comment) ->
    @commentBtnWorking = true

    @materialService.addComment(@materialId, { content: comment }).then(
      (data) =>
        @log.debug "Created comment, result", data
        @comments.push data

        @newComment = null

        @analytics.eventTrack('Posted comment', { Category: 'Comments', id: data.id });

      (failure) =>
        @log.error "Error creating comment", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @commentBtnWorking = false
    )

  removeComment: (comment) ->
    @removedComments.push(comment)
    @comments = @differenceFilter(@comments, @removedComments)

    @materialService.removeComment(@materialId, comment.id).then(
      (data) =>
        @log.debug "Comment removed successfully", data

        @setSelectedIndex(null)

        @analytics.eventTrack('Removed comment', { Category: 'Comments', id: comment.id });

      (failure) =>
        @log.error "Comment remove failed", failure
        @error = @errorHandlerService.handle(failure)

        @removedComments.pop()
        @comments = @differenceFilter(@comments, @removedComments)
    )

  removeCommentAllowed: (comment) ->
    comment.user_id == @sessionService.getUserId() || @isManager

  setSelectedIndex: (index) ->
    @selectedIndex = index

  handleError: ->
    @reload()

  reload: ->
    @error = null

    if @accessDenied
      @window.history.back()
      return

    if @materialId?
      @_initMaterial()
    else
      @_initEmptyMaterial()

materialApp = angular.module "materialApp",
  [
    "appConfig"
    "participantModule"
    "meetingModule"
    "ngAnimate"
    "nativeUi"
    "mtnSwipeToReveal"
    "mtnListFilters"
    "dateHelper"
    "contenteditable"
    "mtnMoveCursorToEnd"
    "mtnUtils"
    "autoGrow"
    "mtnURL"
  ]

materialApp.controller "MaterialShowCtrl", MaterialShowCtrl
