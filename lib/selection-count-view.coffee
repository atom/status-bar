class SelectionCountView extends HTMLElement
  initialize: (@statusBar) ->
    @classList.add('selection-count', 'inline-block')

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToActiveTextEditor()

  destroy: ->
    @activeItemSubscription.dispose()
    @selectionSubscription?.dispose()

  subscribeToActiveTextEditor: ->
    @selectionSubscription?.dispose()
    @selectionSubscription = atom.workspace.getActiveTextEditor()?.onDidChangeSelectionRange =>
      @updateCount()
    @updateCount()

  updateCount: ->
    count = atom.workspace.getActiveTextEditor()?.getSelectedText().length
    if count > 0
      @textContent = "(#{count})"
    else
      @textContent = ''

module.exports = document.registerElement('status-bar-selection', prototype: SelectionCountView.prototype, extends: 'div')
