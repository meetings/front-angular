matchmakerModule = angular.module "matchmakerModule", [ "appConfig" ]

matchmakerModule.service "matchmakerService", (
  $q
  SessionRestangular
  LocalDataRestangular
  sessionService
  currentUserService
  dateHelper
  cacheService) ->

  setCache: (matchmakers) ->
    cacheService.put("matchmakers", matchmakers)

  getCache: ->
    return cacheService.get("matchmakers")

  setMatchmakerObject: (matchmaker) ->
    @matchmaker = matchmaker

  getMatchmakerObject: ->
    if @matchmaker?
      return @matchmaker

    else
      user = currentUserService.get()
      return {
                user_id: sessionService.getUserId()
                duration: 30
                buffer: 30
                name: "Lunch with " + user.name
                time_zone: user.time_zone
                meeting_type: "2"
              }

  # Remove matchmakers with timespan ending before current day or meetme_hidden is 1
  filterMatchmakers: (matchmakers) ->
    return _(matchmakers).filter((matchmaker) ->
      if matchmaker.available_timespans?.length > 0
        return matchmaker.available_timespans[0].end >= dateHelper.todayEpoch()

      return true
    ).where({meetme_hidden: 0})
    .value()

  checkMeetmeUrlAvailability: (meetmeFragment) ->
    deferred = $q.defer()

    SessionRestangular.one("users").get(user_fragment: meetmeFragment).then(
      (data) =>
        deferred.reject( "Meet me url unavailable" )

      (failure) =>
        if failure.status == 404
          deferred.resolve()
        else
          deferred.reject(failure)
    )

    return deferred.promise

  addMatchmaker: (matchmaker) ->
    return currentUserService.getRoute().post("matchmakers", matchmaker)

  fetchMatchmakers: ->
    return currentUserService.getRoute().all("matchmakers").getList()

  fetchLunchScheduler: ->
    return LocalDataRestangular.all("lunch_scheduler").getList()
