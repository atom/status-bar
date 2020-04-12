'use babel'
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let SelectionCountView;
import _ from 'underscore-plus';

export default SelectionCountView = class SelectionCountView {
  constructor() {
    let left;
    this.element = document.createElement('status-bar-selection');
    this.element.classList.add('selection-count', 'inline-block');

    this.tooltipElement = document.createElement('div');
    this.tooltipDisposable = atom.tooltips.add(this.element, {item: this.tooltipElement});

    this.formatString = (left = atom.config.get('status-bar.selectionCountFormat')) != null ? left : '(%L, %C)';

    this.activeItemSubscription = atom.workspace.onDidChangeActiveTextEditor(() => this.subscribeToActiveTextEditor());

    this.subscribeToConfig();
    this.subscribeToActiveTextEditor();
  }

  destroy() {
    this.activeItemSubscription.dispose();
    if (this.selectionSubscription != null) {
      this.selectionSubscription.dispose();
    }
    if (this.configSubscription != null) {
      this.configSubscription.dispose();
    }
    return this.tooltipDisposable.dispose();
  }

  subscribeToConfig() {
    if (this.configSubscription != null) {
      this.configSubscription.dispose();
    }
    return this.configSubscription = atom.config.observe('status-bar.selectionCountFormat', value => {
      this.formatString = value != null ? value : '(%L, %C)';
      return this.scheduleUpdateCount();
    });
  }

  subscribeToActiveTextEditor() {
    if (this.selectionSubscription != null) {
      this.selectionSubscription.dispose();
    }
    const activeEditor = this.getActiveTextEditor();
    const selectionsMarkerLayer = activeEditor != null ? activeEditor.selectionsMarkerLayer : undefined;
    this.selectionSubscription = selectionsMarkerLayer != null ? selectionsMarkerLayer.onDidUpdate(this.scheduleUpdateCount.bind(this)) : undefined;
    return this.scheduleUpdateCount();
  }

  getActiveTextEditor() {
    return atom.workspace.getActiveTextEditor();
  }

  scheduleUpdateCount() {
    if (!this.scheduledUpdate) {
      this.scheduledUpdate = true;
      return atom.views.updateDocument(() => {
        this.updateCount();
        return this.scheduledUpdate = false;
      });
    }
  }

  updateCount() {
    // optional chaining rewritten:
    let count, range;
    const editor = atom.workspace.getActiveTextEditor();
    if (editor) {
      count = editor.getSelectedText().length;
      range = editor.getSelectedBufferRange();
    }

    let lineCount = range != null ? range.getRowCount() : undefined;
    if ((range != null ? range.end.column : undefined) === 0) { lineCount -= 1; }
    if (count > 0) {
      this.element.textContent = this.formatString.replace('%L', lineCount).replace('%C', count);
      return this.tooltipElement.textContent = `${_.pluralize(lineCount, 'line')}, ${_.pluralize(count, 'character')} selected`;
    } else {
      this.element.textContent = '';
      return this.tooltipElement.textContent = '';
    }
  }
};
