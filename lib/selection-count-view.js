import _ from 'underscore-plus';

export default class SelectionCountView {
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
    this.selectionSubscription?.dispose();
    this.configSubscription?.dispose();
    this.tooltipDisposable.dispose();
  }

  subscribeToConfig() {
    this.configSubscription?.dispose();
    this.configSubscription = atom.config.observe('status-bar.selectionCountFormat',
        value => {
          this.formatString = value ? value : '(%L, %C)';
          this.scheduleUpdateCount();
        }
    );
  }

  subscribeToActiveTextEditor() {
    this.selectionSubscription?.dispose();
    const activeEditor = this.getActiveTextEditor();
    const selectionsMarkerLayer = activeEditor?.selectionsMarkerLayer;
    this.selectionSubscription = selectionsMarkerLayer?.onDidUpdate(this.scheduleUpdateCount.bind(this));
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
    const editor = atom.workspace.getActiveTextEditor();
    const count = editor?.getSelectedText().length;
    const range = editor?.getSelectedBufferRange();
    let lineCount = range?.getRowCount();
    if (range?.end.column === 0) { lineCount -= 1; }
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
