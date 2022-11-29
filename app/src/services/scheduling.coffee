schedulingModule = angular.module 'schedulingModule', ['appConfig']

schedulingModule.service 'schedulingService', ($log, meetingService, SessionRestangular, appConfig, dateHelper) ->

  @scheduling = null

  ############
  # API
  ############

  startScheduling: (meetingId, params) ->
    return meetingService.meetingRoute(meetingId).post("schedulings", params)

  schedulingsRoute: (meetingId, schedulingsId) ->
    return meetingService.meetingRoute(meetingId).one("schedulings", schedulingsId)

  fetchScheduling: (meetingId, schedulingsId) ->
    return @schedulingsRoute(meetingId, schedulingsId).get()

  fetchOption: (meetingId, schedulingsId, optionId) ->
    return @schedulingsRoute(meetingId, schedulingsId).one("options", optionId).get()

  fetchNextOption: (meetingId, schedulingsId) ->
    return @schedulingsRoute(meetingId, schedulingsId).post("provide_next_option")

  fetchNextOptions: (meetingId, schedulingsId, optionId, parentOptionId, parentAnswer) ->
    params = {
      parent_option_id: parentOptionId
      parent_option_answer: parentAnswer
    }
    return @schedulingsRoute(meetingId, schedulingsId).one("options", optionId).post("provide_next_options", params)

  answerOption: (meetingId, schedulingsId, optionId, answer) ->
    params = {
      answer: answer
    }
    return @schedulingsRoute(meetingId, schedulingsId).one("options", optionId).post("answers", params)

  ############
  # UTILS
  ############

  setScheduling: (scheduling) ->
    @scheduling = scheduling

  getScheduling: ->
    if @scheduling?
      return SessionRestangular.copy(@scheduling)

    return {}

  formatSelectedDays: (days) ->
    selectedDays = []
    _.each(days, (day, index) ->
      if day
        selectedDays.push(index)
    )

    return selectedDays

  formatSchedulingSlots: (days, beginSecond, endSecond) ->
    slots = []
    for i in days by 1
      slots.push({
        weekday: i
        begin_second: beginSecond
        end_second: endSecond
      })

    return slots

  getSelectedDaysFromSlots: (slots) ->
    days = [false, false, false, false, false, false, false]
    _.each(slots, (slot) ->
      days[slot.weekday] = true
    )

    return days

  isValidScheduling: (s2m) ->
    errors = {
      msg: ""
    }

    # Is timespan end set before today?
    if s2m.scheduling.available_timespans[0].end? &&
       s2m.scheduling.available_timespans[0].end < dateHelper.todayEpoch()
      errors.invalidTimespanEnd = true
      errors.msg += "Scheduling end date is set before this day."

    # Is timespan end set before timespan start?
    if s2m.scheduling.available_timespans[0].end? &&
       s2m.scheduling.available_timespans[0].end <= s2m.scheduling.available_timespans[0].start
      errors.invalidTimespan = true
      if errors.msg != ""
        errors.msg += "<br>"
      errors.msg += "Scheduling end date is set before start date."

    # Do not check for matchmaker templates
    if s2m.scheduling.is_scheduling_template
      if s2m.scheduling.slots.length == 0
        errors.invalidTime = true
        if errors.msg != ""
          errors.msg += "<br>"
        errors.msg += "At least one day should be selected."

      if s2m.scheduling.slots.length > 0
        # Is duration longer than timeframe?
        timeframeSeconds = s2m.scheduling.slots[0].end_second - s2m.scheduling.slots[0].begin_second
        if s2m.scheduling.duration * 60 > timeframeSeconds
          errors.invalidDuration = true
          if errors.msg != ""
            errors.msg += "<br>"
          errors.msg += "Duration is longer than the timeframe."

        if s2m.scheduling.slots[0].end_second <= s2m.scheduling.slots[0].begin_second
          errors.invalidTime = true
          if errors.msg != ""
            errors.msg += "<br>"
          errors.msg += "End time is before start time."

    return errors
