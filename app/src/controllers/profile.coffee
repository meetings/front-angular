
class ProfileBaseCtrl
  @$inject =
  [
    "$scope"
    "$rootScope"
    "$location"
    "$window"
    "$log"
    "appConfig"
    "SessionRestangular"
    "sessionService"
    "currentUserService"
    "errorHandlerService"
    "materialService"
    "navigationBarService"
    "uncacheableUrl"
    "deviceUtils"
  ]

  constructor: (@scope
                @rootScope
                @location
                @window
                @log
                @appConfig
                @SessionRestangular
                @sessionService
                @currentUserService
                @errorHandlerService
                @materialService
                @navigationBarService
                @uncacheableUrl
                @deviceUtils) ->

    @isDevelopmentMode = @appConfig.isDevelopmentMode


class ProfileEditCtrl extends ProfileBaseCtrl

  constructor: ->
    super

    @_setLayout()
    @_reloadUser()

  #############
  # PRIVATE
  #############

  _setLayout: ->
    @navigationBarService.show("Profile")

    cancelButton = {
      title: "Cancel"
      onClick: =>
        @cancelEdit()
    }

    saveButton = {
      title: "Done"
      onClick: =>
        @rootScope.$broadcast("blurInput")
        @update()
    }

    @navigationBarService.update(
      buttons:
        left: if @deviceUtils.platform() != "web" then cancelButton else null
        right: if @deviceUtils.platform() == "ios" then saveButton else null
    )

  _reloadUser: ->
    @loading = true
    @delayedSpinner = true

    @currentUserService.reload({ image_size: @appConfig.thumbnail.large }).then(
      (user) =>
        @user = user
        @profileImageUrl = @uncacheableUrl(user.image)

      (failure) =>
        @log.error "Failed to load user data"
        @reloadRequired = true
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  #############
  # PUBLIC
  #############

  cancelEdit: ->
    @rootScope.$broadcast("blurInput")
    @window.history.back()

  update: ->
    if !@scope.edit.profile.$valid
      @error = @errorHandlerService.handleAppError(@errorHandlerService.INVALID_LINKEDIN_URL)
      return

    @loading = true
    @delayedSpinner = false

    @currentUserService.update(@user).then(
      (data) =>
        @log.debug "Updated user success, got data:", data

        @window.history.back()

      (failure) =>
        @log.debug "Failed updating user", failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  addPhoto: ->
    if @uploadProgress? || @deviceUtils.platform() == "web"
      return

    @materialService.addPhoto(@appConfig.thumbnail.large).then(
      (data) =>
        @log.debug "Profile picture successfully uploaded"
        @user.upload_id = data.result.upload_id
        @profileImageUrl = @uncacheableUrl(data.result.upload_thumbnail_url)

      (failure) =>
        @log.error "Failed to upload profile picture", failure
        @reloadRequired = false
        @error = @errorHandlerService.handle failure

      (progress) =>
        @uploadProgress = progress

    ).finally(
      =>
        @uploadProgress = null
    )

  removePhoto: ->
    @user.upload_id = -1

    @update()

  handleError: ->
    @error = null

    if @reloadRequired
      @_reloadUser()

profileApp = angular.module "profileApp",
  [
    "appConfig"
    "nativeUi"
    "currentUserModule"
    "mtnProgress"
    "mtnFloatLabel"
    "mtnUtils"
  ]

profileApp.controller "ProfileEditCtrl", ProfileEditCtrl
