describe 'Directive: mtnError', ->
  beforeEach module("mtnDialogs")

  @$compile = null
  @$scope = null

  beforeEach inject ($compile, $rootScope) ->
    @$compile = $compile
    @$scope = $rootScope

  it "generates the error markup", ->
    element = angular.element """
      <mtn-error ng-model="error">
    """

    @$scope.error = { message: "This is the expected error message." }
    @$compile(element)(@$scope)
    @$scope.$digest()

    expect(element.hasClass('ng-hide')).toBeFalsy()
    expect(element.text()).toContain("This is the expected error message.")

  it "displays button", ->
    element = angular.element """
      <mtn-error ng-model="error" mtn-button-click="reload()">
    """

    @$scope.error = { message: "This is the expected error message.", buttonCaption: "OK" }
    @$compile(element)(@$scope)
    @$scope.$digest()

    expect( element.find("button").text() ).toBe("OK", "Expected button caption")
    expect( element.find("button").hasClass('ng-hide') ).toBeFalsy("Expected button be hidden")
