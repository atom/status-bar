class CursorPositionView extends HTMLElement
  initialize: ->
    @classList.add('cursor-position', 'inline-block')

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToActiveTextEditor()

  destroy: ->
    @activeItemSubscription.dispose()
    @cursorSubscription?.dispose()

  subscribeToActiveTextEditor: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updatePosition()
    @updatePosition()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updatePosition: ->
    if position = @getActiveTextEditor()?.getCursorBufferPosition()
      @textContent = "#{position.row + 1},#{position.column + 1}"
    else
      @textContent = ''

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
