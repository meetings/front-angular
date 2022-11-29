meetingGroupUtils = angular.module "meetingGroupUtils", ["dateHelper"]

meetingGroupUtils.factory "meetingGroupUtils", (dateHelper, groupAndFilter) ->

  ############
  # PRIVATE
  ############

  #############
  # PUBLIC
  #############

  groupMeetings: (ungroupedMeetings) ->
    meetings = {}

    # FUTURE
    meetings.today = groupAndFilter ungroupedMeetings, true, (m) =>
      dateHelper.isEpochToday(m.begin_epoch)

    meetings.thisWeekUpcoming = groupAndFilter ungroupedMeetings, true, (m) =>
      dateHelper.isEpochThisWeekInFuture(m.begin_epoch)

    meetings.nextWeek = groupAndFilter ungroupedMeetings, true, (m) =>
      dateHelper.isEpochNextWeek(m.begin_epoch)

    meetings.furtherInFuture = groupAndFilter ungroupedMeetings, true, (m) =>
      dateHelper.isEpochFurtherInFuture(m.begin_epoch, 7) && !dateHelper.isEpochNextWeek(m.begin_epoch)

    # PAST
    meetings.yesterday = groupAndFilter ungroupedMeetings, false, (m) =>
      dateHelper.isEpochYesterday(m.begin_epoch)

    meetings.thisWeekBefore = groupAndFilter ungroupedMeetings, false, (m) =>
      dateHelper.isEpochThisWeekInPast(m.begin_epoch) && !dateHelper.isEpochYesterday(m.begin_epoch)

    meetings.lastWeek = groupAndFilter ungroupedMeetings, false, (m) =>
      dateHelper.isEpochLastWeek(m.begin_epoch)

    meetings.furtherInPast = groupAndFilter ungroupedMeetings, false, (m) =>
      dateHelper.isEpochFurtherInPast(m.begin_epoch, 7) && !dateHelper.isEpochLastWeek(m.begin_epoch)

    # WITHOUT DATE
    meetings.unscheduled = _(ungroupedMeetings).filter((m) =>
      dateHelper.isEpochUnset(m.begin_epoch)
    ).groupBy('title')
    .map()
    .value()

    return meetings

meetingGroupUtils.factory "groupAndFilter", ->
  (meetings, sortOrder, filter) ->
    _(meetings).filter(filter)
      .sortByOrder(['begin_epoch'], [sortOrder])
      .groupBy('date_string')
      .map()
      .value()
