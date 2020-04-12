'use babel'
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let FileInfoView;
import { Disposable } from 'atom';
import url from 'url';
import fs from 'fs-plus';

export default FileInfoView = class FileInfoView {
  constructor() {
    this.element = document.createElement('status-bar-file');
    this.element.classList.add('file-info', 'inline-block');

    this.currentPath = document.createElement('a');
    this.currentPath.classList.add('current-path');
    this.element.appendChild(this.currentPath);
    this.element.currentPath = this.currentPath;

    this.element.getActiveItem = this.getActiveItem.bind(this);

    this.activeItemSubscription = atom.workspace.getCenter().onDidChangeActivePaneItem(() => {
      return this.subscribeToActiveItem();
    });
    this.subscribeToActiveItem();

    this.registerTooltip();
    const clickHandler = event => {
      const isShiftClick = event.shiftKey;
      this.showCopiedTooltip(isShiftClick);
      const text = this.getActiveItemCopyText(isShiftClick);
      atom.clipboard.write(text);
      return setTimeout(() => {
        return this.clearCopiedTooltip();
      }
      , 2000);
    };

    this.element.addEventListener('click', clickHandler);
    this.clickSubscription = new Disposable(() => this.element.removeEventListener('click', clickHandler));
  }

  registerTooltip() {
    return this.tooltip = atom.tooltips.add(this.element, { title() {
      return "Click to copy absolute file path (Shift + Click to copy relative path)";
    }
  });
  }

  clearCopiedTooltip() {
    if (this.copiedTooltip != null) {
      this.copiedTooltip.dispose();
    }
    return this.registerTooltip();
  }

  showCopiedTooltip(copyRelativePath) {
    if (this.tooltip != null) {
      this.tooltip.dispose();
    }
    if (this.copiedTooltip != null) {
      this.copiedTooltip.dispose();
    }
    const text = this.getActiveItemCopyText(copyRelativePath);
    return this.copiedTooltip = atom.tooltips.add(this.element, {
      title: `Copied: ${text}`,
      trigger: 'manual',
      delay: {
        show: 0
      }
    }
    );
  }

  getActiveItemCopyText(copyRelativePath) {
    // optional chaining rewritten:
    let path, title;
    const activeItem = this.getActiveItem();
    if (activeItem) {
      path = activeItem.getPath();
    }

    if ((path == null)) { return activeItem.getTitle() || ''; }

    // Make sure we try to relativize before parsing URLs.
    if (copyRelativePath) {
      const relativized = atom.project.relativize(path);
      if (relativized !== path) {
        return relativized;
      }
    }

    // An item path could be a url, we only want to copy the `path` part
    if ((path != null ? path.indexOf('://') : undefined) > 0) {
      ({
        path
      } = url.parse(path));
    }
    return path;
  }

  subscribeToActiveItem() {
    if (this.modifiedSubscription != null) {
      this.modifiedSubscription.dispose();
    }
    if (this.titleSubscription != null) {
      this.titleSubscription.dispose();
    }
    let activeItem = this.getActiveItem();
    if (activeItem) {
      if (this.updateCallback == null) { this.updateCallback = () => this.update(); }

      // optional chaining:
      if (typeof activeItem.onDidChangeTitle === 'function') {
        this.titleSubscription = activeItem.onDidChangeTitle(this.updateCallback);
      } else if (typeof activeItem.on === 'function') {
        //TODO Remove once title-changed event support is removed
        activeItem.on('title-changed', this.updateCallback);
        this.titleSubscription = { dispose: () => {
            // optional chaining:
            return (typeof activeItem.off === 'function' ? activeItem.off('title-changed', this.updateCallback) : undefined);
        }
      };
      }

      // optional chaining:
      this.modifiedSubscription = typeof activeItem.onDidChangeModified === 'function' ? activeItem.onDidChangeModified(this.updateCallback) : undefined;
    }

    return this.update();
  }

  destroy() {
    this.activeItemSubscription.dispose();
    if (this.titleSubscription != null) {
      this.titleSubscription.dispose();
    }
    if (this.modifiedSubscription != null) {
      this.modifiedSubscription.dispose();
    }
    if (this.clickSubscription != null) {
      this.clickSubscription.dispose();
    }
    if (this.copiedTooltip != null) {
      this.copiedTooltip.dispose();
    }
    return (this.tooltip != null ? this.tooltip.dispose() : undefined);
  }

  getActiveItem() {
    return atom.workspace.getCenter().getActivePaneItem();
  }

  update() {
    this.updatePathText();
    // optional chaining rewritten:
    let isModified;
    const activeItem = this.getActiveItem();
    if (activeItem && typeof activeItem.isModified === 'function') {
      isModified = activeItem.isModified();
    }
    return this.updateBufferHasModifiedText(isModified);
  }

  updateBufferHasModifiedText(isModified) {
    if (isModified) {
      this.element.classList.add('buffer-modified');
      return this.isModified = true;
    } else {
      this.element.classList.remove('buffer-modified');
      return this.isModified = false;
    }
  }

  updatePathText() {
    // optional chaining rewritten:

    const activeItem = this.getActiveItem();
    if (!activeItem) {
      // if activeItem was null return right away:
      this.currentPath.textContent = '';
      return;
    }

    if (typeof activeItem.getPath == "function") {
      let path = activeItem.getPath();
      if (path) {
        const relativized = atom.project.relativize(path);
        this.currentPath.textContent = (relativized != null) ? fs.tildify(relativized) : path;
        return;
      }
    }

    if (typeof activeItem.getTitle == "function") {
      let title = activeItem.getTitle();
      if (title) {
        this.currentPath.textContent = title;
        return;
      }
    }

    // if title and path were null
    this.currentPath.textContent = '';
  }
};
