# Timeline tab
#
# Has following preloaded WebViews:
# - meetingShowView       - displays meeting#show
class TrialBaseCtrl
  @$inject =
    [
      "$window"
      "appConfig"
      "currentUserService"
      "errorHandlerService"
      "navigationBarService"
      "jsonMsgChannel"
      "viewParams"
    ]

  constructor: (@window,
                @appConfig,
                @currentUserService,
                @errorHandlerService,
                @navigationBarService,
                @msgChannel,
                @viewParams) ->


class TrialIndexCtrl extends TrialBaseCtrl

  constructor: ->
    super

    @_reloadUser()
    @_setLayout()

  ############
  # PRIVATE
  ############

  _reloadUser: ->
    @loading = true
    @delayedSpinner = true

    @currentUserService.reload({ image_size: @appConfig.thumbnail.small }).then(
      (user) =>
        @user = user

        @isTrialExpired = @currentUserService.isTrialExpired(user)

      (failure) =>
        @log.error "Failed to load user data"
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _setLayout: ->
    title = if @isTrialExpired then "Trial expired" else "Start trial"

    @navigationBarService.update({
      title: title
    })

  ############
  # PUBLIC
  ############

  startTrial: ->
    @loading = true

    @currentUserService.startTrial().then(
      (data) =>
        user = @currentUserService.get()
        user.is_trial_pro = 1
        @msgChannel.publish JSON.stringify(
          event: "updateUser"
          user: user
        )

        @window.history.back()

      (failure) =>
        @error = @errorHandlerService.handle failure
    ).finally(
      =>
        @loading = false
    )

  sendProFeaturesEmail: ->
    @loading = true

    @currentUserService.sendProFeaturesEmail().then(
      (data) =>
        @window.history.back()

      (failure) =>
        @error = @errorHandlerService.handle failure
    ).finally(
      =>
        @loading = false
    )

  cancel: ->
    @window.history.back()

  handleError: ->
    @error = null
    @_reloadUser()


trialApp = angular.module 'trialApp',
  [
    'appConfig'
  ]

trialApp.controller("TrialIndexCtrl", TrialIndexCtrl)

