class CursorPositionView extends HTMLElement
  initialize: ->
    @classList.add('cursor-position', 'inline-block')

    @formatString = atom.config.get('status-bar.cursorPositionFormat') ? '%L:%C'
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToConfig()
    @subscribeToActiveTextEditor()

    @tooltip = atom.tooltips.add(this, title: ->
      "Line #{@row}, Column #{@column}")

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
      @formatString = value ? '%L:%C'
      @updatePosition()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updatePosition: ->
    if editor = @getActiveTextEditor()
      screenpos = editor.getCursorScreenPosition()
      bufpos = editor.getCursorBufferPosition()
      buffer = editor.getBuffer()
      @row = bufpos.row + 1
      @column = screenpos.column + 1
      @lineCount = editor.getLineCount()
      @percent = Math.round(100 * @row / @lineCount)
      @length = buffer.getText().length # BUG: doesn't update on backspace
      @textContent = @formatString
        .replace('%L', @row)
        .replace('%C', @column)
        .replace('%l', @lineCount)
        .replace('%p', @percent)
        .replace('%z', @length)
    else
      @textContent = ''

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
