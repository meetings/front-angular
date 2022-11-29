describe "Date Helper Service", ->

  @dateHelper = null

  beforeEach module('dateHelper')

  beforeEach inject (dateHelper) ->
   @dateHelper = dateHelper

  epoch = (date) ->
    return date.valueOf() / 1000

  describe "Epoch basics", ->

    it 'defines cases when an epoch is undefined', ->
      expect(@dateHelper.isEpochUnset(0)).toBeTruthy()
      expect(@dateHelper.isEpochUnset("0")).toBeTruthy()
      expect(@dateHelper.isEpochUnset(null)).toBeTruthy()
      expect(@dateHelper.isEpochUnset(undefined)).toBeTruthy()

    it 'defines cases when an epoch is defined', ->
      expect(@dateHelper.isEpochUnset(1)).toBeFalsy()
      expect(@dateHelper.isEpochUnset("1")).toBeFalsy()
      expect(@dateHelper.isEpochUnset("1234567890")).toBeFalsy()


  describe "duration", ->

    it 'calculates hours and minutes', ->
      expect(@dateHelper.durationString(1388648, 1394048)).toEqual("1 h 30 min")

    it 'returns empty string when duration is less than 1 minute', ->
      expect(@dateHelper.durationString(1388648, 1388649)).toEqual("")

    it 'calculates days, hours and minutes', ->
      expect(@dateHelper.durationString(1388648256, 1389953256)).toEqual("15 days")

    it 'handles invalid values e.g. strings', ->
      expect(@dateHelper.durationString("string", "another string")).toEqual("")


  describe "meeting default time", ->

    beforeEach ->
      Timecop.install()

    afterEach ->
       Timecop.uninstall()

    it 'begins noon of today when time is before 12:00', ->
      Timecop.travel(new Date(2014, 1, 2, 11, 59)); # Today at 11:59

      noonToday = moment().startOf('day').add(12, 'hours').format("X") # Today at 12:00

      expect(@dateHelper.defaultNewMeetingBeginDate()).toEqual(noonToday)

    it 'begins noon of tomorrow when time is after 12:00', ->
      Timecop.travel(new Date(2014, 1, 2, 12, 0)); # Today at 12:00

      noonTomorrow = moment().startOf('day').add(12, 'hours').add(1, 'days').format("X") # Tomorrow at 12:00

      expect(@dateHelper.defaultNewMeetingBeginDate()).toEqual(noonTomorrow)

    it 'ends one hour after given begin time', ->
      begin = "1388676170"
      oneHourAfter = "1388679770"

      expect(@dateHelper.defaultNewMeetingEndDate(begin)).toEqual(oneHourAfter)


  describe "date ranges", ->

    today = null
    todayEpoch = null
    yesterday = null
    yesterdayEpoch = null
    tomorrow = null
    tomorrowEpoch = null

    # Time is frozen at
    # Friday 31th January 2014 at 13:30
    beforeEach ->
      Timecop.install()
      Timecop.travel(new Date(2014, 0, 31, 13, 30)) # Timecop.freeze() does not work well with momentjs

      todayDate = new Date(2014, 0, 31)
      today = todayDate.toISOString()
      todayEpoch = epoch todayDate

      tomorrowDate = new Date(2014, 1, 1)
      tomorrow = tomorrowDate.toISOString()
      tomorrowEpoch = epoch tomorrowDate

      yesterdayDate = new Date(2014, 0, 30)
      yesterday = yesterdayDate.toISOString()
      yesterdayEpoch = epoch yesterdayDate

    afterEach ->
      Timecop.uninstall()

    describe "for today", ->

      it 'as a moment', ->
        expect(@dateHelper.today().toISOString()).toEqual(today)

      it 'as an epoch', ->
        expect(@dateHelper.todayEpoch()).toEqual(todayEpoch)

      it 'succeeds if epoch is today', ->
        expect(@dateHelper.isEpochToday(todayEpoch)).toBeTruthy()

      it 'fails if epoch is not today', ->
        dayBeforeYesterday = epoch new Date(2014, 0, 29)

        expect(@dateHelper.isEpochToday(yesterday)).toBeFalsy()
        expect(@dateHelper.isEpochToday(dayBeforeYesterday)).toBeFalsy()

    describe "for tomorrow", ->
      it 'as a moment', ->
        expect(@dateHelper.tomorrow().toISOString()).toEqual(tomorrow)

      it 'as an epoch', ->
        expect(@dateHelper.tomorrowEpoch()).toEqual(tomorrowEpoch)

      it 'succeeds if epoch is tomorrow', ->
        expect(@dateHelper.isEpochTomorrow(tomorrowEpoch)).toBeTruthy()

      it 'fails if epoch is not tomorrow', ->
        expect(@dateHelper.isEpochTomorrow(today)).toBeFalsy()
        expect(@dateHelper.isEpochTomorrow(yesterday)).toBeFalsy()

    describe "for yesterday", ->

      it 'as a moment', ->
        expect(@dateHelper.yesterday().toISOString()).toEqual(yesterday)

      it 'as an epoch', ->
        expect(@dateHelper.yesterdayEpoch()).toEqual(yesterdayEpoch)

      it 'succeeds if epoch is yesterday', ->
        expect(@dateHelper.isEpochYesterday(yesterdayEpoch)).toBeTruthy()

      it 'fails if epoch is not yesterday', ->
        dayBeforeYesterday = epoch new Date(2014, 0, 29)

        expect(@dateHelper.isEpochYesterday(dayBeforeYesterday)).toBeFalsy()

    describe "for this week", ->

      it 'returns start of this week as moment', ->
        sunday = new Date(2014, 0, 26).toISOString()

        expect(@dateHelper.thisWeekStart().toISOString()).toEqual(sunday)

      it 'returns start of this week as epoch', ->
        sunday = epoch new Date(2014, 0, 26)

        expect(@dateHelper.thisWeekStartEpoch()).toEqual(sunday)

      it 'returns end of this week as moment', ->
        endOfSaturday = new Date(2014, 1, 1, 23, 59, 59, 999).toISOString()

        expect(@dateHelper.thisWeekEnd().toISOString()).toEqual(endOfSaturday)

      it 'returns end of this week as epoch', ->
        endOfSaturday = epoch new Date(2014, 1, 1, 23, 59, 59)

        expect(@dateHelper.thisWeekEndEpoch()).toEqual(endOfSaturday)

      it 'succeeds if given epoch is in this week', ->
        weekEndingSaturday = epoch new Date(2014, 1, 1, 23, 59, 59)
        weekStartingSunday = epoch new Date(2014, 0, 26)

        expect(@dateHelper.isEpochThisWeek(weekEndingSaturday)).toBeTruthy()
        expect(@dateHelper.isEpochThisWeek(weekStartingSunday)).toBeTruthy()
        expect(@dateHelper.isEpochThisWeek(todayEpoch)).toBeTruthy()

      it 'fails if given epoch is not in this week', ->
        lastWeekEnds  = epoch new Date(2014, 0, 25, 23, 59, 59)
        nextWeekStarts  = epoch new Date(2014, 1, 2)

        expect(@dateHelper.isEpochThisWeek(lastWeekEnds)).toBeFalsy()
        expect(@dateHelper.isEpochThisWeek(nextWeekStarts)).toBeFalsy()

      it 'succeeds if epoch is this week in future', ->
        endOfSaturday = epoch new Date(2014, 1, 1, 23, 59, 59)

        expect(@dateHelper.isEpochThisWeekInFuture(tomorrowEpoch)).toBeTruthy()
        expect(@dateHelper.isEpochThisWeekInFuture(endOfSaturday)).toBeTruthy()


      it 'fails if epoch is not this week in future', ->
        sunday = epoch new Date(2014, 0, 26)

        expect(@dateHelper.isEpochThisWeekInFuture(todayEpoch)).toBeFalsy()
        expect(@dateHelper.isEpochThisWeekInFuture(yesterdayEpoch)).toBeFalsy()
        expect(@dateHelper.isEpochThisWeekInFuture(sunday)).toBeFalsy()


    describe "for next week", ->

      it 'returns start of next week as moment', ->
        sunday = new Date(2014, 1, 2).toISOString()

        expect(@dateHelper.nextWeekStart().toISOString()).toEqual(sunday)

      it 'returns start of next week as epoch', ->
        sunday = epoch new Date(2014, 1, 2)

        expect(@dateHelper.nextWeekStartEpoch()).toEqual(sunday)

      it 'returns end of next week as moment', ->
        endOfSaturday = new Date(2014, 1, 8, 23, 59, 59, 999).toISOString()

        expect(@dateHelper.nextWeekEnd().toISOString()).toEqual(endOfSaturday)

      it 'returns end of next week as epoch', ->
        endOfSaturday = epoch new Date(2014, 1, 8, 23, 59, 59)

        expect(@dateHelper.nextWeekEndEpoch()).toEqual(endOfSaturday)

      it 'succeeds if given epoch is in next week', ->
        weekStartingSunday = epoch new Date(2014, 1, 2)
        weekEndingSaturday = epoch new Date(2014, 1, 8, 23, 59, 59)

        expect(@dateHelper.isEpochNextWeek(weekStartingSunday)).toBeTruthy()
        expect(@dateHelper.isEpochNextWeek(weekEndingSaturday)).toBeTruthy()

      it 'fails if given epoch is not in next week', ->
        thisWeekEnds = epoch new Date(2014, 1, 1, 23, 59, 59)
        weekAfterNextWeekStarts = epoch new Date(2014, 1, 9)

        expect(@dateHelper.isEpochNextWeek(thisWeekEnds)).toBeFalsy()
        expect(@dateHelper.isEpochNextWeek(weekAfterNextWeekStarts)).toBeFalsy()


    describe "for last week", ->
      it 'returns start of last week as moment', ->
        sunday = new Date(2014, 0, 19).toISOString()

        expect(@dateHelper.lastWeekStart().toISOString()).toEqual(sunday)

      it 'returns start of last week as epoch', ->
        sunday = epoch new Date(2014, 0, 19)

        expect(@dateHelper.lastWeekStartEpoch()).toEqual(sunday)

      it 'returns end of last week as moment', ->
        endOfSaturday = new Date(2014, 0, 25, 23, 59, 59, 999).toISOString()

        expect(@dateHelper.lastWeekEnd().toISOString()).toEqual(endOfSaturday)

      it 'returns end of last week as epoch', ->
        endOfSaturday = epoch new Date(2014, 0, 25, 23, 59, 59)

        expect(@dateHelper.lastWeekEndEpoch()).toEqual(endOfSaturday)

      it 'succeeds if given epoch is in last week', ->
        weekStartingSunday = epoch new Date(2014, 0, 19)
        weekEndingSaturday = epoch new Date(2014, 0, 25, 23, 59, 59)

        expect(@dateHelper.isEpochLastWeek(weekStartingSunday)).toBeTruthy()
        expect(@dateHelper.isEpochLastWeek(weekEndingSaturday)).toBeTruthy()

      it 'fails if given epoch is not in last week', ->
        thisWeekStarts = epoch new Date(2014, 0, 26)
        weekBeforeLastWeekEnds = epoch new Date(2014, 0, 18, 23, 59, 59)

        expect(@dateHelper.isEpochLastWeek(thisWeekStarts)).toBeFalsy()
        expect(@dateHelper.isEpochLastWeek(weekBeforeLastWeekEnds)).toBeFalsy()


    describe "for this year", ->

      it 'returns end of this year as an epoch', ->
        yearEnd = epoch new Date(2014, 11, 31, 23, 59, 59)

        expect(@dateHelper.thisYearEndEpoch()).toEqual(yearEnd)

      it 'returns start of this year as an epoch', ->
        yearStart = epoch new Date(2014, 0, 1)

        expect(@dateHelper.thisYearStartEpoch()).toEqual(yearStart)

      it 'succeeds if given epoch is in this year', ->
        yearStart = epoch new Date(2014, 0, 1)
        yearEnd = epoch new Date(2014, 11, 31, 23, 59, 59)

        expect(@dateHelper.isEpochThisYear(todayEpoch)).toBeTruthy()
        expect(@dateHelper.isEpochThisYear(yearStart)).toBeTruthy()
        expect(@dateHelper.isEpochThisYear(yearEnd)).toBeTruthy()


    describe "for specific units of time", ->

      it 'succeeds if epoch is further in the past', ->
        furtherInPast = epoch new Date(2014, 0, 23, 23, 59, 59)

        expect(@dateHelper.isEpochFurtherInPast(furtherInPast, 7)).toBeTruthy()

      it 'fails if epoch is not further in the past', ->
        exactlyAtTheBorder = epoch new Date(2014, 0, 24)

        expect(@dateHelper.isEpochFurtherInPast(exactlyAtTheBorder, 7)).toBeFalsy()

      it 'does not count epoch 0 being in the past', ->
        undefinedEpochInt = 0
        undefinedEpochStr = "0"

        expect(@dateHelper.isEpochFurtherInPast(undefinedEpochInt, 7)).toBeFalsy()
        expect(@dateHelper.isEpochFurtherInPast(undefinedEpochStr, 7)).toBeFalsy()

      it 'succeeds if epoch if further in the future', ->
        furtherInFuture = epoch new Date(2014, 1, 7, 0, 0, 1)

        expect(@dateHelper.isEpochFurtherInFuture(furtherInFuture, 7)).toBeTruthy()

      it 'fails if epoch is not further in the furuture', ->
        exactlyAtTheBorder = epoch new Date(2014, 1, 7)

        expect(@dateHelper.isEpochFurtherInFuture(exactlyAtTheBorder, 7)).toBeFalsy()

      it 'knows this day of week', ->
        friday = 5

        expect(@dateHelper.dayOfWeek()).toEqual(friday)

      it 'is in future', ->
        inPast = epoch new Date(2014, 0, 30, 23, 59, 59)
        expect(@dateHelper.isEpochInFuture(inPast)).toBeFalsy()

        inFuture = epoch new Date(2014, 1, 1, 12, 0, 0)
        expect(@dateHelper.isEpochInFuture(inFuture)).toBeTruthy()

