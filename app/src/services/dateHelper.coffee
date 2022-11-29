dateHelper = angular.module 'dateHelper', []


dateHelper.service 'dateHelper', ($log) ->

  oneDayInSeconds: 24 * 60 * 60

  # Give nicer names for moment's custom long date formats

  # Thu, April 16, 2015
  formatDayDateYear: "ddd, MMMM D, YYYY"

  # April 16, 2015
  formatDateYear: "MMMM D, YYYY"

  # April 16
  formatDate: "MMMM D"

  # 11:30 am, Thu, Apr 16
  formatTimeDayDate: "LT, ddd, MMM D"

  # 11:30 am, Apr 16
  formatTimeDate: "LT, ddd, MMM D"

  # Thu, Apr 16
  formatDayDate: "ddd, MMM D"

  # Thursday
  formatDayOfWeek: "dddd"

  # Thu
  formatDayOfWeekShort: "ddd"

  # Th
  formatDayOfWeekShortest: "dd"

  # 11:30 am
  formatTime: "LT"

  # Create custom long date formats for formatting times and days based on whether current user uses 12h or 24h time format
  initCustomLocales: ->
    moment.locale("12h", {
      longDateFormat: {
        # Use unicode non-breaking space, thanks angular!
        LT: "h:mm\u00A0a"
      }
    })

    moment.locale("24h", {
      longDateFormat: {
        LT: "H:mm"
      }
    })

  # Default new meeting begin date is the next noon (either this or the next day).
  # Returns an epoch.
  defaultNewMeetingBeginDate: ->
    nextNoon = moment().startOf('day').add(12, 'hours')
    nextNoon.add(1, 'days') if moment().get('hour') >= 12

    return nextNoon.format("X")

  # Default meeting duration is 1 hours.
  # Returns an epoch which is 1 hours later than given argument "begin".
  defaultNewMeetingEndDate: (begin) ->
    oneHourAfter = moment.unix(begin).add(1, 'hours')

    return oneHourAfter.format("X")

  # Default new scheduling begin date is the midnight this day.
  # Returns an epoch.
  defaultNewSchedulingBeginDate: ->
    start = moment().startOf('day')

    return start.format("X")

  # Default scheduling timespan is 1 month.
  # Returns an epoch which is 1 month later than given argument "begin".
  defaultNewSchedulingEndDate: (begin) ->
    oneMonthAfter = moment.unix(begin).add(1, 'months')

    return oneMonthAfter.format("X")

  durationString: (begin, end) ->
    duration = moment.duration(end - begin, "seconds")

    dDays = duration.days()

    if dDays >= 1
      return duration.humanize()

    dHourString = if duration.hours() != 0 then duration.hours() + " h " else ""
    dMinuteString = if duration.minutes() != 0 then duration.minutes() + " min" else ""

    return dHourString + dMinuteString

  # API returns epoch values as string.
  isEpochUnset: (epoch) ->
    return epoch == "0" || epoch == 0 || !epoch

  todayEpoch: ->
    @today().unix()

  today: ->
    moment().startOf('day')

  yesterdayEpoch: ->
    @yesterday().unix()

  yesterday: ->
    @today().subtract(1, 'days')

  tomorrow: ->
    @today().add(1, 'days')

  tomorrowEpoch: ->
    @tomorrow().unix()

  dayOfWeek: ->
    moment().day()

  isEpochTomorrow: (epoch) ->
    date = ("YYYY-MM-DD")

    moment.unix(epoch).format(date) == @tomorrow().format(date)

  isEpochYesterday: (epoch) ->
    date = ("YYYY-MM-DD")

    moment.unix(epoch).format(date) == @yesterday().format(date)

  isEpochToday: (epoch) ->
    date = ("YYYY-MM-DD")

    moment.unix(epoch).format(date) == @today().format(date)

  thisWeekStart: ->
    moment().startOf('week')

  thisWeekStartEpoch: ->
    @thisWeekStart().unix()

  thisWeekEnd: ->
    moment().endOf('week')

  thisWeekEndEpoch: ->
    @thisWeekEnd().unix()

  isEpochThisWeek: (epoch) ->
    epoch >= @thisWeekStartEpoch() && epoch <= @thisWeekEndEpoch()

  isEpochThisWeekInPast: (epoch) ->
    epoch < @yesterday().unix() && epoch >= @thisWeekStartEpoch()

  isEpochThisWeekInFuture: (epoch) ->
    @isEpochThisWeek(epoch) && epoch >= @tomorrowEpoch()

  nextWeekStart: ->
    @thisWeekStart().add(1, 'weeks')

  nextWeekStartEpoch: ->
    @nextWeekStart().unix()

  nextWeekEnd: ->
    @thisWeekEnd().add(1, 'weeks')

  nextWeekEndEpoch: ->
    @nextWeekEnd().unix()

  isEpochNextWeek: (epoch) ->
    epoch >= @nextWeekStartEpoch() && epoch <= @nextWeekEndEpoch()

  isEpochFurtherInFuture: (epoch, days) ->
    epoch > moment().startOf('day').add(days, 'days').unix()

  lastWeekEnd: ->
    @thisWeekEnd().subtract(1, 'weeks')

  lastWeekEndEpoch: ->
    @lastWeekEnd().unix()

  lastWeekStart: ->
    @thisWeekStart().subtract(1, 'weeks')

  lastWeekStartEpoch: ->
    @lastWeekStart().unix()

  isEpochLastWeek: (epoch) ->
    epoch >= @lastWeekStartEpoch() && epoch <= @lastWeekEndEpoch()

  isEpochFurtherInPast: (epoch, days) ->
    epoch < @today().subtract(days, 'days').unix() && !@isEpochUnset(epoch)

  thisYearStartEpoch: ->
    moment().startOf('year').unix()

  thisYearEndEpoch: ->
    moment().endOf('year').unix()

  isEpochThisYear: (epoch) ->
    epoch >= @thisYearStartEpoch() && epoch <= @thisYearEndEpoch()

  isEpochInFuture: (epoch) ->
    epoch > @todayEpoch()

  isDurationOverADay: (startEpoch, endEpoch) ->
    return endEpoch - startEpoch > 23 * 60 * 60 + 59 * 60 # 23 hours, 59 minutes

  dateToEpoch: (date) ->
    return moment(date).format("X")

  formatTimezone: (timezone) ->
    return moment().tz(timezone).format("Z")
