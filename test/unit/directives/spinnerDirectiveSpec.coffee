describe 'Directive: mtnSpinner', ->
  beforeEach module("mtnSpinner")

  @$compile = null
  @$scope = null

  beforeEach inject ($compile, $rootScope) ->
    @$compile = $compile
    @$scope = $rootScope

  it "generates the spinner markup", ->
    element = angular.element """
      <mtn-spinner>
    """

    @$compile(element)(@$scope)
    @$scope.$digest()

    expect(element.html()).toContain('')

  it "generates a spinner tag with ng-show", ->
    element = angular.element """
      <mtn-spinner ng-show="true">
    """

    @$compile(element)(@$scope)
    @$scope.$digest()

    expect(element.html()).toContain('')

  it "generates a spinner tag with ng-hide", ->
    element = angular.element """
      <mtn-spinner ng-hide="false">
    """

    @$compile(element)(@$scope)
    @$scope.$digest()

    expect(element.html()).toContain('')

  it "generates a spinner tag that is hidden when ng-show is set to false", ->
    @$scope.loading = true

    element = angular.element """
      <mtn-spinner ng-show="loading">
    """

    @$compile(element)(@$scope)
    @$scope.$digest()

    expect(element.html()).toContain('')

    @$scope.loading = false

    @$scope.$digest()

    expect(element.html()).toContain('')
