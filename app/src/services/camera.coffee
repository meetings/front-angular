cameraModule = angular.module 'cameraModule', []


cameraModule.service 'cameraService', ($log) ->

  getPicture: (successCallback, errorCallback) =>

    # Cordova Camera plugin is *really* picky what comes to options.
    # Malformed options result in unstable performance in crashes.
    #
    # See: http://docs.appgyver.com/en/edge/cordova_camera_camera.md.html#cameraOptions
    #
    defaults = {
      quality: 50
      sourceType: Camera.PictureSourceType.PHOTOLIBRARY
    }

    $log.debug "camera options are:", defaults

    navigator.camera.getPicture successCallback, errorCallback, defaults

