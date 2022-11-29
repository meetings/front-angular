describe "Grouping meetings", ->

  beforeEach angular.mock.module('meetingGroupUtils')

  beforeEach inject (meetingGroupUtils) ->
    @meetingGroupUtils = meetingGroupUtils

  epoch = (date) ->
    return date.valueOf() / 1000

  describe "by date", ->

    afterEach ->
      Timecop.uninstall()

    # Time is frozen at
    # Friday 31th January 2014 at 13:30
    beforeEach ->
      Timecop.install()

      Timecop.travel(new Date(2014, 0, 31, 13, 30)) # Timecop.freeze() does not work well with momentjs

      @meetingsToday = [
        { id: "100", begin_epoch: epoch new Date(2014, 0, 31) }
        { id: "101", begin_epoch: epoch new Date(2014, 0, 31, 23, 59, 59) }
      ]

      @meetingsYesterday = [
        { id: "201", begin_epoch: epoch new Date(2014, 0, 30, 23, 59, 59) }
        { id: "200", begin_epoch: epoch new Date(2014, 0, 30) }
      ]

      @meetingsThisWeekUpcoming = [
        { id: "300", begin_epoch: epoch new Date(2014, 1, 1) }
        { id: "301", begin_epoch: epoch new Date(2014, 1, 1) }
      ]

      @meetingsNextWeek = [
        { id: "400", begin_epoch: epoch new Date(2014, 1, 2) }
        { id: "401", begin_epoch: epoch new Date(2014, 1, 8) }
      ]

      @meetingsFurtherInFuture = [
        { id: "500", begin_epoch: epoch new Date(2014, 1, 9) }
        { id: "501", begin_epoch: epoch new Date(2014, 11, 1) }
      ]

      @meetingsLastWeek = [
        { id: "601", begin_epoch: epoch new Date(2014, 0, 25) }
        { id: "600", begin_epoch: epoch new Date(2014, 0, 19) }
      ]

      @meetingsFurtherInPast = [
        { id: "700", begin_epoch: epoch new Date(2014, 0, 18) }
        { id: "701", begin_epoch: epoch new Date(2010, 0, 1) } # NOTE: Year
      ]

      @meetingsThisWeekBefore = [
        { id: "800", begin_epoch: epoch new Date(2014, 0, 29) }
        { id: "801", begin_epoch: epoch new Date(2014, 0, 26) }
      ]

      @meetingsUnscheduled = [
        { id: "10000", begin_epoch: "0" }
        { id: "10001", begin_epoch: "" }
      ]



      @ungrouped = _.union(
        @meetingsToday, @meetingsYesterday, @meetingsThisWeekUpcoming,
        @meetingsNextWeek, @meetingsFurtherInFuture, @meetingsLastWeek,
        @meetingsFurtherInPast, @meetingsUnscheduled, @meetingsThisWeekBefore
      )

      @grouped = @meetingGroupUtils.groupMeetings @ungrouped

    it "has today", ->
      expect( @grouped.today[0] ).toEqual @meetingsToday

    it "has yesterday", ->
      expect( @grouped.yesterday[0] ).toEqual @meetingsYesterday

    it "has this week upcoming", ->
      expect( @grouped.thisWeekUpcoming[0] ).toEqual @meetingsThisWeekUpcoming

    it "has this week before", ->
      expect( @grouped.thisWeekBefore[0]).toEqual @meetingsThisWeekBefore

    it "has next week", ->
      expect( @grouped.nextWeek[0] ).toEqual @meetingsNextWeek

    it "has further in future", ->
      expect( @grouped.furtherInFuture[0] ).toEqual @meetingsFurtherInFuture

    it "has last week", ->
      expect( @grouped.lastWeek[0] ).toEqual @meetingsLastWeek

    it "has further in past", ->
      expect( @grouped.furtherInPast[0] ).toEqual @meetingsFurtherInPast

    it "has unscheduled", ->
      expect( @grouped.unscheduled[0] ).toEqual @meetingsUnscheduled
