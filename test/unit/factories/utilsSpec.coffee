describe "Utils factory", ->

  beforeEach angular.mock.module('mtnUtils')

  describe "uncacheable url", ->

    it "returns an url with a changing query parameter", inject (uncacheableUrl) ->
      url = "http://www.example.com/image.png"
      uncacheable = uncacheableUrl(url)
      expect( uncacheable ).toContain url + "?"
      expect( uncacheable ).not.toEqual url + "?"

    it "returns null when given url is not defined", inject (uncacheableUrl) ->
      expect( uncacheableUrl(null) ).toBeNull()
      expect( uncacheableUrl("") ).toBeNull()
      expect( uncacheableUrl(undefined) ).toBeNull()

    it "returns different urls on subsequent requests", inject (uncacheableUrl) ->
      Timecop.install()

      url = "http://www.example.com/image.png"

      Timecop.travel(new Date(2014, 1, 2, 11, 59));
      first  = uncacheableUrl(url)

      Timecop.travel(new Date(2014, 1, 2, 12, 0));
      second = uncacheableUrl(url)

      Timecop.travel(new Date(2014, 1, 2, 12, 1));
      third  = uncacheableUrl(url)

      expect( first ).not.toEqual second
      expect( first ).not.toEqual third
      expect( second ).not.toEqual third

      Timecop.uninstall()

