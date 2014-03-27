{View} = require 'atom'

module.exports =
class CursorPositionView extends View
  @content: ->
    @div class: 'cursor-position inline-block'

  initialize: (@statusBar) ->
    @subscribe @statusBar, 'active-buffer-changed', @updateCursorPositionText
    @subscribe atom.workspaceView, 'cursor:moved', @updateCursorPositionText

  destroy: ->
    @remove()

  afterAttach: ->
    @updateCursorPositionText()

  updateCursorPositionText: =>
    editor = atom.workspace.getActiveEditor()
    if position = editor?.getCursorBufferPosition()
      @text("#{position.row + 1},#{position.column + 1}").show()
    else
      @hide()
