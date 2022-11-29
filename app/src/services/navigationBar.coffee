navigationBarModule = angular.module "navigationBarModule", [ "mtnUtils" ]

navigationBarModule.service "navigationBarService", ($rootScope, $window, $location, deviceUtils) ->

  menuVisible: true
  navBarVisible: true

  # Returns a default back button if showBackButton is true.
  # ShowBackButton is used because Steroids app uses native back button in most cases
  defaultBackButton: ->
    return {
      title: "Back"
      onClick: =>
        $rootScope.$broadcast("blurInput")
        $window.history.back()
    }

  # Returns a back button with destination path if showBackButton is true.
  # ShowBackButton is used because Steroids app uses native back button in most cases
  buttonToPath: (path) ->
    return {
      title: "Back"
      onClick: =>
        $rootScope.$broadcast("blurInput")
        $location.path(path)
    }

  # Update navigation bar.
  # Usage:
  #   @navigationBarService.update(options)
  #
  #   options:
  #     {
  #       title: string
  #       right: {
  #         title: string
  #         imagePath: string
  #         onClick: function
  #       }
  #       left: {
  #         title: string
  #         imagePath: string
  #         onClick: function
  #       }
  #     }
  #
  #  Note: Supports only one right button and one left button.
  #
  update: (options) ->
    if options.title?
      @title = options.title

    @leftButton = null
    @rightButton = null

    if options.buttons?.left?
      if deviceUtils.platform() != "ios"
        @hideMenu()
      @leftButton = options.buttons.left

    else
      @showMenu()

    if options.buttons?.right?
      @rightButton = options.buttons.right


  show: (title) ->
    @navBarVisible = true
    @title = title

  hide: ->
    @navBarVisible = false

  hideMenu: ->
    @menuVisible = false

  showMenu: ->
    @menuVisible = true
