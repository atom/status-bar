let SelectionCountView;
import _ from 'underscore-plus';

export default SelectionCountView = class SelectionCountView {
  constructor() {
    this.element = document.createElement('status-bar-selection');
    this.element.classList.add('selection-count', 'inline-block');

    this.tooltipElement = document.createElement('div');
    this.tooltipDisposable = atom.tooltips.add(this.element, {
      item: this.tooltipElement
    });

    const selectionCountFormat = atom.config.get(
      'status-bar.selectionCountFormat'
    );
    if (selectionCountFormat) {
      this.formatString = selectionCountFormat;
    } else {
      this.formatString = '(%L, %C)';
    }

    this.activeItemSubscription = atom.workspace.onDidChangeActiveTextEditor(
      () => this.subscribeToActiveTextEditor()
    );

    this.subscribeToConfig();
    this.subscribeToActiveTextEditor();
  }

  destroy() {
    this.activeItemSubscription.dispose();
    if (this.selectionSubscription) {
      this.selectionSubscription.dispose();
    }
    if (this.configSubscription) {
      this.configSubscription.dispose();
    }
    this.tooltipDisposable.dispose();
  }

  subscribeToConfig() {
    if (this.configSubscription) {
      this.configSubscription.dispose();
    }
    this.configSubscription = atom.config.observe(
      'status-bar.selectionCountFormat',
      value => {
        this.formatString = value ? value : '(%L, %C)';
        this.scheduleUpdateCount();
      }
    );
  }

  subscribeToActiveTextEditor() {
    if (this.selectionSubscription) {
      this.selectionSubscription.dispose();
    }
    const activeEditor = this.getActiveTextEditor();
    const selectionsMarkerLayer = activeEditor
      ? activeEditor.selectionsMarkerLayer
      : undefined;
    this.selectionSubscription = selectionsMarkerLayer
      ? selectionsMarkerLayer.onDidUpdate(this.scheduleUpdateCount.bind(this))
      : undefined;
    this.scheduleUpdateCount();
  }

  getActiveTextEditor() {
    return atom.workspace.getActiveTextEditor();
  }

  scheduleUpdateCount() {
    if (!this.scheduledUpdate) {
      this.scheduledUpdate = true;
      atom.views.updateDocument(() => {
        this.updateCount();
        this.scheduledUpdate = false;
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

    let lineCount, rangeEndColumn;
    if (range) {
      lineCount = range.getRowCount();
      rangeEndColumn = range.end.column;
    }
    if (rangeEndColumn === 0) {
      lineCount -= 1;
    }
    if (count > 0) {
      this.element.textContent = this.formatString
        .replace('%L', lineCount)
        .replace('%C', count);
      this.tooltipElement.textContent = `${_.pluralize(
        lineCount,
        'line'
      )}, ${_.pluralize(count, 'character')} selected`;
    } else {
      this.element.textContent = '';
      this.tooltipElement.textContent = '';
    }
  }
};
