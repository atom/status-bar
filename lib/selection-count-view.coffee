{View} = require 'atom'

module.exports =
class SelectionCountView extends View
  @content: ->
    @div class: "selection-count inline-block"

  initialize: (@statusBar) ->
    @subscribe atom.workspaceView.eachEditorView (editor) =>
      @subscribe editor, "selection:changed", @updateCount
    @subscribe @statusBar, "active-buffer-changed", @updateCount

  destroy: ->
    @remove()

  afterAttach: ->
    @updateCount()

  updateCount: =>
    count = atom.workspace.getActiveEditor()?.getSelection().getText().length
    if count > 0
      @text("(#{count})").show()
    else
      @hide()
