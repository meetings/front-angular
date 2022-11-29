mtnDialogs = angular.module "mtnDialogs", [ "mtnUtils", "mtnUnsafeFilter" ]

# Display an application error.
#
# Attributes:
#  ng-model           : Error message model in format { title: "s", message: "s", buttonCaption: "s" }.
#                       Error container will be hidden if ng-model is undefined.
#  mtn-button-click   : Callback function which will be called from retry button.
#
# Usage:
#  <mtn-error ng-model="index.error"
#             mtn-button-click="index.reload()">
#
mtnDialogs.directive 'mtnError', ->
  restrict: 'E'
  scope:
    ngModel: '='
    mtnButtonClick: '&'

  template: '<div class="popup-overlay"></div>
             <div class="error-container">
              <h1 ng-bind="title">Sorry!</h1>
              <p ng-bind-html="message | unsafe">Error message is missing.</p>
              <button ng-click="mtnButtonClick()">{{buttonCaption}}</button>
            </div>'

  link: (scope, elem, attrs) ->

    scope.$watch "ngModel", (model) ->
      if model
        scope.title = model.title
        scope.message = model.message
        scope.buttonCaption = model.buttonCaption

        if document.documentElement.className.indexOf("popup-active") == -1
          document.documentElement.className += " popup-active"

      else
        document.documentElement.className = document.documentElement.className.replace(" popup-active", "")

# Display a confirm dialog. Similar to mtn-error but with two buttons.
# In multi page app html dialog will be replaced by cordova's native confirmation dialog.
#
# Attributes:
#  ng-model                   : Message model in format { title: "s",
#                                                         message: "s",
#                                                         buttonConfirmCallback: function
#                                                         buttonConfirmCaption: "s"
#                                                         buttonCancelCallback: function
#                                                         buttonCancelCaption: "s"
#                                                       }
#                               Dialog container will be hidden if ng-model is undefined.
#
# Usage:
#  <mtn-confirm ng-model="index.confirmDialog">
#
mtnDialogs.directive 'mtnConfirm', (deviceUtils) ->
  restrict: 'E'
  scope:
    ngModel: '='

  template: ->
    if deviceUtils.platform() != "web"
      return ""

    return '<div class="popup-overlay"></div>
              <div class="dialog-container">
               <h1 ng-bind="title">Hello!</h1>
               <p ng-bind="message">Message is missing.</p>
               <button class="dual" ng-click="buttonConfirmCallback()">
                 {{buttonConfirmCaption}}
               </button>
               <button class="dual secondary" ng-click="buttonCancelCallback()">
                 {{buttonCancelCaption}}
               </button>
             </div>'

  link: (scope, elem, attrs) ->

    showNativeDialog = (model) ->
      navigator.notification.confirm(
        model.message,
        (selected) ->
          if (selected == 1)
            model.buttonConfirmCallback()
          else
            model.buttonCancelCallback()
        ,
        model.title,
        [model.buttonConfirmCaption, model.buttonCancelCaption]
      )

    showHtmlDialog = (model) ->
      scope.title = model.title
      scope.message = model.message
      scope.buttonConfirmCallback = model.buttonConfirmCallback
      scope.buttonConfirmCaption = model.buttonConfirmCaption
      scope.buttonCancelCallback = model.buttonCancelCallback
      scope.buttonCancelCaption = model.buttonCancelCaption

      if document.documentElement.className.indexOf("popup-active") == -1
        document.documentElement.className += " popup-active"

    scope.$watch "ngModel", (model) ->
      if model
        if deviceUtils.platform() == "web"
          showHtmlDialog(model)
        else
          showNativeDialog(model)

      else
        document.documentElement.className = document.documentElement.className.replace(" popup-active", "")
