describe 'Directive: epochToMoment', ->
  beforeEach module("epochToMoment")

  @$compile = null
  @$scope = null

  beforeEach inject ($compile, $rootScope) ->
    @$compile = $compile
    @$scope = $rootScope

    @$scope.meeting = {begin_epoch: "1234567890", end_epoch: "1234583490"}


  describe "duration", ->
    beforeEach inject ($compile, $rootScope) ->
      @element = angular.element """
        <duration>
          <begin ng-model="meeting.begin_epoch"></begin>
          <end   ng-model="meeting.end_epoch"></end>
        </duration>
      """

      @$compile(@element)(@$scope)
      @$scope.$digest()


    it "calculates hours and minutes", inject ($compile) ->
      expect(@element.text()).toEqual("4 h 20 min")


    it "calculates new value when model data is changed", inject ($compile) ->

      expect(@element.text()).toEqual("4 h 20 min")

      @$scope.meeting = { begin_epoch: "1388483567", end_epoch: "1388537627"}

      @$compile(@element)(@$scope)
      @$scope.$digest()

      expect(@element.text()).toEqual("15 h 1 min")


  describe "mtnPreserveDuration", ->
    beforeEach inject ($compile, $rootScope) ->
      @element = angular.element """
        <mtn-datetime-input ng-model="meeting.end_epoch"
                     mtn-preserve-duration
                     mtn-model-begin="meeting.begin_epoch"
                     mtn-model-end="meeting.end_epoch">
        </mtn-datetime-input>
      """

      @$compile(@element)(@$scope)
      @$scope.$digest()


    it "preserve duration by changing end time when begin time is changed", inject ($compile) ->

      expect(@element.val()).toEqual("2009-02-14T05:51:30")

      # move begin epoch back one hour
      @$scope.meeting = {begin_epoch: "1234564290", end_epoch: "1234583490"}
      @$scope.$digest()

      expect(@element.val()).toEqual("2009-02-14T04:51:30")


  describe "mtnEnsureMinDuration", ->
    beforeEach inject ($compile, $rootScope) ->
      @beginElement = angular.element """
        <mtn-datetime-input ng-model="meeting.begin_epoch"></mtn-datetime-input>
      """
      @endElement = angular.element """
        <mtn-datetime-input ng-model="meeting.end_epoch"
                     mtn-ensure-min-duration
                     mtn-model-begin="meeting.begin_epoch"
                     mtn-model-end="meeting.end_epoch">
        </mtn-datetime-input>
      """

      @$compile(@beginElement)(@$scope)
      @$compile(@endElement)(@$scope)
      @$scope.$digest()


    it "Ensure minimun duration of meeting", inject ($compile) ->

      expect(@endElement.val()).toEqual("2009-02-14T05:51:30")

      # move begin epoch back one hour
      @$scope.meeting = {begin_epoch: "1234567890", end_epoch: "1234565490"}
      @$scope.$digest()

      expect(@beginElement.val()).toEqual("2009-02-14T00:36:30")
