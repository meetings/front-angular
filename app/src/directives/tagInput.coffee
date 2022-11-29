mtnTagInput = angular.module "mtnTagInput", [ "ngSanitize", "contenteditable" ]

mtnTagInput.directive "mtnTagInput", ($rootScope) ->
  restrict: 'E'
  template: '<div class="tags" ng-click="focusInput()">
               <ul class="tag-list">
                 <li class="label">{{tagLabel}}</li>
                 <li ng-repeat="tag in tagList | filter:filterTags"
                     ng-click="removeTag(tag)"
                     class="tag-item"
                     ng-class="{ selected: tag == tagList.selected }"
                     ng-bind="tag[displayProperty]"></li>
               </ul>
               <div class="input"
                    ng-model="inputModel"
                    contenteditable="true"
                    autocapitalize="words"
                    autocomplete="off"
                    autocorrect="off"></div>
             </div>'

  scope:
    tagList: '=ngModel'
    inputModel: '=inputModel'
    tagLabel: '@label'
    onAddTag: '&mtnOnAddTag'
    onRemoveTag: '&mtnOnRemoveTag'
    tagFilter: '&mtnTagFilter'

  link: (scope, elem, attrs) ->
    scope.displayProperty = attrs.mtnDisplayProperty
    scope.hideProperty = attrs.mtnHideProperty

    scope.filterTags = (tag) ->
      scope.tagFilter(tag: tag)

    scope.$watch("inputModel", (value) ->
      if value? && value.length > 0
        scope.tagList.selected = null
    )

    elem.bind "keydown", (e) ->
      key = e.which

      # Tab, Enter
      if key is 9 or key is 13
        e.preventDefault()

        if scope.onAddTag?
          scope.onAddTag()

        scope.$apply()

      # Backspace
      if key is 8 && (!scope.inputModel? || scope.inputModel == "")
        scope.removeTag()
        scope.$apply()

    scope.removeTag = (tag) ->
      if tag?
        if scope.tagList.selected == tag

          if scope.onRemoveTag?
            scope.onRemoveTag(tag: scope.tagList.selected)

          else
            _.remove(scope.tagList, tag)

          scope.tagList.selected = null

        else
          scope.tagList.selected = tag

      else if scope.tagList.selected?

        if scope.onRemoveTag?
          scope.onRemoveTag(tag: scope.tagList.selected)

        else
          _.remove(scope.tagList, scope.tagList.selected)

        scope.tagList.selected = null

      else
        scope.tagList.selected = _.last(scope.tagList)

    scope.addTag = (tagName) ->
      if tagName? && tagName != ""
        tag = {}
        tag[scope.displayProperty] = tagName
        scope.tagList.push(tag)

    scope.focusInput = ($event) ->
      $rootScope.$broadcast("focusInput")
