_ = require 'underscore-plus'

module.exports =
class SelectionCountView
  constructor: ->
    @element = document.createElement('status-bar-selection')
    @element.classList.add('selection-count', 'inline-block')

    @formatString = atom.config.get('status-bar.selectionCountFormat') ? '(%L, %C)'
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveTextEditor()

    @subscribeToConfig()
    @subscribeToActiveTextEditor()

  destroy: ->
    @activeItemSubscription.dispose()
    @selectionSubscription?.dispose()
    @configSubscription?.dispose()

  subscribeToConfig: ->
    @configSubscription?.dispose()
    @configSubscription = atom.config.observe 'status-bar.selectionCountFormat', (value) =>
      @formatString = value ? '(%L, %C)'
      @updateCount()

  subscribeToActiveTextEditor: ->
    @selectionSubscription?.dispose()
    activeEditor = @getActiveTextEditor()
    @selectionSubscription = activeEditor?.onDidChangeSelectionRange ({selection}) =>
      return unless selection is activeEditor.getLastSelection()
      @updateCount()
    @updateCount()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateCount: ->
    count = @getActiveTextEditor()?.getSelectedText().length
    range = @getActiveTextEditor()?.getSelectedBufferRange()
    lineCount = range?.getRowCount()
    lineCount -= 1 if range?.end.column is 0
    if count > 0
      @element.textContent = @formatString.replace('%L', lineCount).replace('%C', count)
      title = "#{_.pluralize(lineCount, 'line')}, #{_.pluralize(count, 'character')} selected"
      @toolTipDisposable?.dispose()
      @toolTipDisposable = atom.tooltips.add @element, title: title
    else
      @element.textContent = ''
