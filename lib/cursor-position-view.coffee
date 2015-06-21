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
    if editor = @getActiveTextEditor()
      screenpos = editor.getCursorScreenPosition()
      bufpos = editor.getCursorBufferPosition()
      @row = bufpos.row + 1
      @column = screenpos.column + 1
      @lineCount = editor.getLineCount()
      @length = editor.getText().length
      @offset = editor.getTextInBufferRange([[0, 1], bufpos]).length
      @percent = Math.round(100 * @offset / @length)
      @textContent = @formatString(@statusFormat)
    else
      @textContent = ''

  formatString: (str) ->
    str
      .replace('%L', @row)
      .replace('%C', @column)
      .replace('%l', @lineCount)
      .replace('%z', @length)
      .replace('%o', @offset)
      .replace('%p', @percent)
      .replace('\\n', '<br/>')

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
