describe "Error Helper Service", ->

  beforeEach module('errorHandler')

  describe "create", ->

    beforeEach inject (errorHandlerService) ->
      @handler = errorHandlerService

    it "creates an error message", ->
      msg = "This is the expected message"
      error = @handler.msg(msg)

      expect( error.message ).toEqual msg

