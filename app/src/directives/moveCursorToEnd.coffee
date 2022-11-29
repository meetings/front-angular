mtnMoveCursorToEnd = angular.module "mtnMoveCursorToEnd", []

mtnMoveCursorToEnd.directive "mtnMoveCursorToEnd", ->
  restrict: 'A'
  link: (scope, elem, attrs) ->

    moveCursorToEndOfTextArea = ->
      length = elem[0].value.length
      elem[0].setSelectionRange(length, length)

    moveCursorToEndOfContentEditable = ->
      range = document.createRange()
      range.selectNodeContents(elem[0])
      range.collapse(false)
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)


    bind = ->
      isContentEditable = attrs.contenteditable?

      elem[0].addEventListener 'focus', ->
        if isContentEditable
          moveCursorToEndOfContentEditable()
        else
          moveCursorToEndOfTextArea()

    bind()
