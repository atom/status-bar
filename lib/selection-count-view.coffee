module.exports =
class SelectionCountView extends HTMLElement
  initialize: (@statusBar) ->
    @classList.add('selection-count', 'inline-block')

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (textEditor) =>
      @selectionSubscription?.dispose()
      @selectionSubscription = textEditor.onDidChangeSelectionRange? => @updateCount()

    @selectionSubscription = atom.workspace.getActiveTextEditor()?.onDidChangeSelectionRange => @updateCount()
    @updateCount()

  destroy: ->
    @activeItemSubscription.dispose()
    @selectionSubscription?.dispose()

  updateCount: ->
    count = atom.workspace.getActiveTextEditor()?.getSelectedText().length
    if count > 0
      @textContent = "(#{count})"
    else
      @textContent = ''

module.exports = document.registerElement('status-bar-selection', prototype: SelectionCountView.prototype, extends: 'div')
