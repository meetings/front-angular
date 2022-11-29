schedulingLogModule = angular.module "schedulingLogModule", [ 'schedulingModule', 'dateHelper', 'mtnUtils' ]

schedulingLogModule.service "schedulingLogService", (schedulingService, dateHelper, cssClassUtils, vsprintfUtils) ->

  ############
  # API
  ############

  logRoute: (meetingId, schedulingsId) ->
    return schedulingService.schedulingsRoute(meetingId, schedulingsId).all("log_entries")

  fetchAll: (meetingId, schedulingsId, params) ->
    return @logRoute(meetingId, schedulingsId).getList(params)

  fetchLogEntry: (meetingId, schedulingsId, id) ->
    return @logRoute(meetingId, schedulingsId).get(lid)

  ############
  # UTILS
  ############

  sortUserStates: (userStateChanges) ->
    userStates = {
      invited: []
      removed: []
      availability_needed: []
      common_time_found: []
    }

    _(userStateChanges).groupBy((stateChange) ->
      return stateChange.data.user_id
    ).each((user) =>
      if user
        lastUserState = _.max(user, "entry_epoch")
        userStates[lastUserState.data.state].push(lastUserState.data)
    ).value()

    return userStates

  # Format last instruction change message
  formatInstructionChanges: (instructionChanges) ->
    lastChange = _.last(instructionChanges)

    return unless lastChange?

    params = vsprintfUtils.formatParams(lastChange)

    return vsprintf(lastChange.msg, params)

  # Iterate through log items and format log messages
  formatLogMessages: (logData) ->
    eventLog = []
    _.each(logData, (item) =>

      params = vsprintfUtils.formatParams(item)
      formattedMsg = vsprintf(item.msg, params)

      switch item.entry_type
        when "instruction_changed"
          # @instruction = formattedMsg

        else # log event
          eventLog.push(formattedMsg: formattedMsg, timestamp: item.entry_epoch)
    )

    return eventLog
