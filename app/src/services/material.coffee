materialModule = angular.module 'materialModule', ['cameraModule', 'appConfig']

materialModule.service 'materialService', ($q, $log, SessionRestangular, cameraService, uploadProgress, appConfig) ->

  # Allows only one simultaneous upload per WebView
  @fileTransfer = null

  materialRoute: (materialId) ->
    return SessionRestangular.one("meeting_materials", materialId)

  getMaterialEditLock: (materialId) ->
    return @materialRoute(materialId).post("edits")

  continueMaterialEdit: (materialId) ->
    return @materialRoute(materialId).post("continue_edit")

  cancelEditing: (editId) ->
    return SessionRestangular.one("meeting_material_edits", editId).remove()

  fetchMaterial: (materialId) ->
    return @materialRoute(materialId).get()

  fetchComments: (materialId) ->
    return @materialRoute(materialId).getList("comments")

  addComment: (materialId, params) ->
    return @materialRoute(materialId).post("comments", params)

  removeComment: (materialId, commentId) ->
    return @materialRoute(materialId).one("comments", commentId).remove()

  removeMaterial: (materialId) ->
    return @materialRoute(materialId).remove()

  updateMaterial: (materialId, editData, content) ->
    material = @materialRoute(materialId)
    material.edit_id = editData.id
    material.content = content
    material.old_content = editData.content

    return material.put()

  #################
  # PHOTO UPLOAD
  #################

  addPhoto: (thumbnailSize) ->

    deferred = $q.defer()

    onSuccess = (fileURL) =>
      @uploadPhoto(fileURL, thumbnailSize).then(
        (data) ->
          deferred.resolve JSON.parse(data.response)

        (failure) ->
          deferred.reject failure

        (fileTransferProgress) ->
          deferred.notify uploadProgress.convert(fileTransferProgress)
      )

    onFailure = (failure) ->
      $log.error "Failed to get picture from plugin:", failure

      return deferred.reject(failure)

    cameraService.getPicture(onSuccess, onFailure)

    return deferred.promise

  uploadPhoto: (fileUrl, thumbnailSize) ->
    endpoint = "#{appConfig.api.baseUrl}/uploads"

    deferred = $q.defer()

    @fileTransfer = new FileTransfer()
    options = new FileUploadOptions()

    fileName = fileUrl.substr(fileUrl.lastIndexOf('/') + 1)

    if fileName?.length
      options.fileName = fileName

    options.params = {
      create_thumbnail: 1
      width : thumbnailSize
      height : thumbnailSize
    }

    @fileTransfer.onprogress = deferred.notify

    # Uploading does not require authentication, anyone can upload anything.
    @fileTransfer.upload(fileUrl, encodeURI(endpoint), deferred.resolve, deferred.reject, options)

    return deferred.promise

  abortAddPhoto: ->
    @fileTransfer.abort()

materialModule.factory 'uploadProgress', ->

  convert: (fileTransferProgress) ->
    {
      loaded: fileTransferProgress.loaded
      total: fileTransferProgress.total
    }
