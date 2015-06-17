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

  getStats: ->
    if editor = @getActiveTextEditor()
      screenpos = editor.getCursorScreenPosition()
      bufpos = editor.getCursorBufferPosition()
      buffer = editor.getBuffer()
      stats =
        line: bufpos.row + 1
        column: screenpos.column + 1
        lineCount: editor.getLineCount()
        percent: 100 * (bufpos.row + 1) / editor.getLineCount()

  updatePosition: ->
    if stats = @getStats()
      @row = stats.line
      @column = stats.column
      @textContent = @formatString
        .replace('%L', stats.line)
        .replace('%C', stats.column)
        .replace('%l', stats.lineCount)
        .replace('%p', Math.round(stats.percent))
    else
      @textContent = ''

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
