describe "Application config", ->

  beforeEach angular.mock.module('appConfig')

  beforeEach inject (appConfig, appEnvironments) ->
    @appConfig = appConfig
    @appEnvironments = appEnvironments

  describe "environment dependent settings for", ->
    describe "api", ->
      it "defines api base url", ->
        expectations = [
          typeof @appConfig.api.baseUrl
          typeof @appEnvironments.staging.api.baseUrl
          typeof @appEnvironments.live.api.baseUrl
        ]

        _.forEach expectations, (each) ->
          expect( each ).toEqual "string"

    describe "googleSignIn", ->
      it "defines google client id", ->
        expectations = [
          typeof @appConfig.googleSignIn.clientId
          typeof @appEnvironments.staging.googleSignIn.clientId
          typeof @appEnvironments.live.googleSignIn.clientId
        ]

        _.forEach expectations, (each) ->
          expect(each).toEqual "number"

      it "defines google login redirect uri back to app", ->
        expectations = [
          typeof @appConfig.googleSignIn.redirectUri
          typeof @appEnvironments.staging.googleSignIn.redirectUri
          typeof @appEnvironments.live.googleSignIn.redirectUri
        ]

        _.forEach expectations, (each) ->
          expect( each ).toEqual "string"

    describe "google", ->
      describe "analytics", ->
        it "defines account id", ->
          expectations = [
            typeof @appConfig.google.analytics.accountId
            typeof @appEnvironments.staging.google.analytics.accountId
            typeof @appEnvironments.live.google.analytics.accountId
          ]

          _.forEach expectations, (each) ->
            expect(each).toEqual "string"

        it "defines how often new analytics data is sent to google (in seconds)", ->
          expectations = [
            typeof @appConfig.google.analytics.updateInterval
            typeof @appEnvironments.staging.google.analytics.updateInterval
            typeof @appEnvironments.live.google.analytics.updateInterval
          ]

          _.forEach expectations, (each) ->
            expect(each).toEqual "number"

        it "defines whether it is enabled ", ->
          expectations = [
            typeof @appConfig.google.analytics.enabled
            typeof @appEnvironments.staging.google.analytics.enabled
            typeof @appEnvironments.live.google.analytics.enabled
          ]

          _.forEach expectations, (each) ->
            expect(each).toEqual "boolean"

  describe "common settings for all environments", ->
    describe "timeline", ->
      it "defines the amount of meetings that are fetched with one request", ->
        expect(typeof @appConfig.timeline.initialMeetingsLimit).toEqual "number"

    describe "meeting", ->
      describe "participants", ->
        it "defines max participant count before participant summary is displayed", ->
          expect(typeof @appConfig.meeting.participants.maxCountBeforeSummary).toEqual "number"

    describe "thumbnail", ->
      it "defines various thumbnail sizes used in app", ->
        expect(typeof @appConfig.thumbnail.small).toEqual "number"
        expect(typeof @appConfig.thumbnail.medium).toEqual "number"
        expect(typeof @appConfig.thumbnail.large).toEqual "number"

    describe "notifications", ->
      it "defines an interval to poll for new notifications", ->
        expect(typeof @appConfig.notifications.pollInterval).toEqual "number"

    describe "calendar", ->
      it "defines an interval to poll for new calendar suggestions", ->
        expect(typeof @appConfig.calendar.pollInterval).toEqual "number"
