'use babel'
let CursorPositionView;
import { Disposable } from 'atom';

export default CursorPositionView = class CursorPositionView {
  constructor() {

    this.viewUpdatePending = false;

    this.element = document.createElement('status-bar-cursor');
    this.element.classList.add('cursor-position', 'inline-block');
    this.goToLineLink = document.createElement('a');
    this.goToLineLink.classList.add('inline-block');
    this.element.appendChild(this.goToLineLink);

    let cursorPositionFormat = atom.config.get('status-bar.cursorPositionFormat');
    this.formatString = cursorPositionFormat ? cursorPositionFormat : '%L:%C';

    this.activeItemSubscription = atom.workspace.onDidChangeActiveTextEditor(activeEditor => this.subscribeToActiveTextEditor());

    this.subscribeToConfig();
    this.subscribeToActiveTextEditor();

    this.tooltip = atom.tooltips.add(this.element, {title: () => `Line ${this.row}, Column ${this.column}`});

    this.handleClick();
  }

  destroy() {
    this.activeItemSubscription.dispose();
    if (this.cursorSubscription) {
      this.cursorSubscription.dispose();
    }
    this.tooltip.dispose();
    if (this.configSubscription) {
      this.configSubscription.dispose();
    }
    this.clickSubscription.dispose();
    this.updateSubscription ? this.updateSubscription.dispose() : undefined;
  }

  subscribeToActiveTextEditor() {
    if (this.cursorSubscription) {
      this.cursorSubscription.dispose();
    }

    const editor = atom.workspace.getActiveTextEditor();
    let selectionsMarkerLayer
    if (editor) {
      selectionsMarkerLayer = editor.selectionsMarkerLayer;
    }

    this.cursorSubscription = selectionsMarkerLayer ? selectionsMarkerLayer.onDidUpdate(this.scheduleUpdate.bind(this)) : undefined;
    this.scheduleUpdate();
  }

  subscribeToConfig() {
    if (this.configSubscription) {
      this.configSubscription.dispose();
    }
    this.configSubscription = atom.config.observe('status-bar.cursorPositionFormat', value => {
      this.formatString = value ? value : '%L:%C';
      this.scheduleUpdate();
    });
  }

  handleClick() {
    const clickHandler = () => atom.commands.dispatch(atom.views.getView(atom.workspace.getActiveTextEditor()), 'go-to-line:toggle');
    this.element.addEventListener('click', clickHandler);
    this.clickSubscription = new Disposable(() => this.element.removeEventListener('click', clickHandler));
  }

  scheduleUpdate() {
    if (this.viewUpdatePending) { return; }

    this.viewUpdatePending = true;
    this.updateSubscription = atom.views.updateDocument(() => {
      this.viewUpdatePending = false;

      const editor = atom.workspace.getActiveTextEditor();
      let position;
      if (editor) {
        position = editor.getCursorBufferPosition();
      }

      if (position) {
        this.row = position.row + 1;
        this.column = position.column + 1;
        this.goToLineLink.textContent = this.formatString.replace('%L', this.row).replace('%C', this.column);
        this.element.classList.remove('hide');
      } else {
        this.goToLineLink.textContent = '';
        this.element.classList.add('hide');
      }
    });
  }
};
