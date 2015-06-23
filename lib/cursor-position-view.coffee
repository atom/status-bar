class CursorPositionView extends HTMLElement
  initialize: ->
    @classList.add('cursor-position', 'inline-block')

    @statusFormat = atom.config.get('status-bar.cursorPositionFormat')
    @tooltipFormat = atom.config.get('status-bar.cursorPositionTooltipFormat')
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToConfig()
    @subscribeToActiveTextEditor()

    @tooltip = atom.tooltips.add(this,
      title: -> @formatString(@tooltipFormat)
      html: true)

  destroy: ->
    @activeItemSubscription.dispose()
    @cursorSubscription?.dispose()
    @tooltip.dispose()
    @configSubscription?.dispose()

  subscribeToActiveTextEditor: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updatePosition()
    @updatePosition()

  subscribeToConfig: ->
    @configSubscription?.dispose()
    @configSubscription = atom.config.observe 'status-bar.cursorPositionFormat', (value) =>
      @statusFormat = value ? '%L:%C'
      @updatePosition()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updatePosition: ->
    @textContent = @formatString(@statusFormat)

  formatString: (str) ->
    if editor = @getActiveTextEditor()
      pos = editor.getCursorBufferPosition()
      size = null
      offset = null
      str
        .replace(/\\n/g, '<br/>')
        .replace('%L', -> pos.row + 1)
        .replace('%C', -> editor.getCursorScreenPosition().column + 1)
        .replace('%l', -> editor.getLineCount())
        .replace('%z', -> size = editor.getText().length)
        .replace('%o', -> offset = editor.getTextInBufferRange([[0, 1], pos]).length)
        .replace('%p', ->
          size = size || editor.getText().length
          offset = offset || editor.getTextInBufferRange([[0, 1], pos]).length
          percent = Math.round(100 * offset / size))
    else
      ''

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
