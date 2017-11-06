const _ = require('underscore-plus')

module.exports =
class SelectionCountView {
  constructor() {
    this.element = document.createElement('status-bar-selection')
    this.element.classList.add('selection-count', 'inline-block')

    this.tooltipElement = document.createElement('div')
    this.tooltipDisposable = atom.tooltips.add(this.element, {item: this.tooltipElement})

    this.formatString = atom.config.get('status-bar.selectionCountFormat') || '(%L, %C)'

    this.activeItemSubscription = atom.workspace.onDidChangeActiveTextEditor(() => this.subscribeToActiveTextEditor())

    this.subscribeToConfig()
    this.subscribeToActiveTextEditor()
  }

  destroy() {
    this.activeItemSubscription.dispose()
    if (this.selectionSubscription) this.selectionSubscription.dispose()
    if (this.configSubscription) this.configSubscription.dispose()
    this.tooltipDisposable.dispose()
  }

  subscribeToConfig() {
    if (this.configSubscription) this.configSubscription.dispose()
    this.configSubscription = atom.config.observe('status-bar.selectionCountFormat', value => {
      this.formatString = value || '(%L, %C)'
      this.scheduleUpdateCount()
    })
  }

  subscribeToActiveTextEditor() {
    if (this.selectionSubscription) this.selectionSubscription.dispose()
    const selectionsMarkerLayer = this.getActiveTextEditor() && this.getActiveTextEditor().selectionsMarkerLayer
    this.selectionSubscription = selectionsMarkerLayer && selectionsMarkerLayer.onDidUpdate(this.scheduleUpdateCount.bind(this))
    this.scheduleUpdateCount()
  }

  getActiveTextEditor() {
    return atom.workspace.getActiveTextEditor()
  }

  scheduleUpdateCount() {
    if (!this.scheduledUpdate) {
      this.scheduledUpdate = true
      return atom.views.updateDocument(() => {
        this.updateCount()
        this.scheduledUpdate = false
      })
    }
  }

  updateCount() {
    const editor = this.getActiveTextEditor()
    const count = editor && editor.getSelectedText().length
    const range = editor && editor.getSelectedBufferRange()
    let lineCount = range && range.getRowCount()
    if (range && range.end.column === 0) lineCount -= 1
    if (count > 0) {
      this.element.textContent = this.formatString.replace('%L', lineCount).replace('%C', count)
      this.tooltipElement.textContent = `${_.pluralize(lineCount, 'line')}, ${_.pluralize(count, 'character')} selected`
    } else {
      this.element.textContent = ''
      this.tooltipElement.textContent = ''
    }
  }
}
