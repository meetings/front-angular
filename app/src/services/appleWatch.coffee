appleWatch = angular.module "appleWatchModule", ['appConfig', 'sessionModule']

appleWatch.service "appleWatchService", ($q, $log, appConfig, sessionService) ->

  init: ->
    deferred = $q.defer()

    if !applewatch?
      deferred.reject("Apple watch plugin not found")

    else
      applewatch.init(
        (appGroupId) =>
          $log.debug "Apple watch plugin init success", appGroupId

          applewatch.addListener("applewatchsignin", () =>
            if sessionService.isSignedIn()
              @signIn(sessionService.getUserId(), sessionService.getToken())
          )

          deferred.resolve()

       (failure) ->
         $log.error "Apple watch plugin init failed", failure
         deferred.reject()

        "group.com.swipetomeet.mobile"
      )

    return deferred.promise

  signIn: (userId, token) ->
    applewatch.sendMessage({
        userId: userId
        token: token
        type: "signin"
      },
      "sessionEvent",
      (success) ->
        $log.debug "Sign in success", success
      (failure) ->
        $log.error "Sign in failed", failure
    )

  signOut: ->
    applewatch.sendMessage({
        type: "signout"
      },
      "sessionEvent",
      (success) ->
        $log.debug "Sign in success", success
      (failure) ->
        $log.error "Sign in failed", failure
    )
