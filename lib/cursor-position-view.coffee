class CursorPositionView extends HTMLElement
  initialize: ->
    @classList.add('cursor-position', 'inline-block')

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToActiveTextEditor()

    @tooltip = atom.tooltips.add(this, title: "Line x, Column y")

  destroy: ->
    @activeItemSubscription.dispose()
    @cursorSubscription?.dispose()
    @tooltip.dispose()

  subscribeToActiveTextEditor: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updatePosition()
    @updatePosition()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updatePosition: ->
    if position = @getActiveTextEditor()?.getCursorBufferPosition()
      row = position.row + 1
      column = position.column + 1
      @textContent = "#{row}:#{column}"
      @tooltip?.dispose()
      @tooltip = atom.tooltips.add(this, title: "Line #{row}, Column #{column}")
    else
      @textContent = ''
      @tooltip?.dispose()

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
