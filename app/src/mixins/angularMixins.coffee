AngularInjectorMixin = {
  getAngularInjector: ->
    return angular.element(document.querySelector("#reactComponentParent")).injector()
}
