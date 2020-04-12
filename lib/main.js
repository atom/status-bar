/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import { CompositeDisposable, Emitter } from 'atom';
import Grim from 'grim';
import StatusBarView from './status-bar-view';
import FileInfoView from './file-info-view';
import CursorPositionView from './cursor-position-view';
import SelectionCountView from './selection-count-view';
import GitView from './git-view';
import LaunchModeView from './launch-mode-view';

export default {
  activate() {
    this.emitters = new Emitter();
    this.subscriptions = new CompositeDisposable();

    this.statusBar = new StatusBarView();
    this.attachStatusBar();

    this.subscriptions.add(atom.config.onDidChange('status-bar.fullWidth', () => {
      return this.attachStatusBar();
    })
    );

    this.updateStatusBarVisibility();

    this.statusBarVisibilitySubscription =
      atom.config.observe('status-bar.isVisible', () => {
        return this.updateStatusBarVisibility();
      });

    atom.commands.add('atom-workspace', 'status-bar:toggle', () => {
      if (this.statusBarPanel.isVisible()) {
        return atom.config.set('status-bar.isVisible', false);
      } else {
        return atom.config.set('status-bar.isVisible', true);
      }
    });

    const {safeMode, devMode} = atom.getLoadSettings();
    if (safeMode || devMode) {
      const launchModeView = new LaunchModeView({safeMode, devMode});
      this.statusBar.addLeftTile({item: launchModeView.element, priority: -1});
    }

    this.fileInfo = new FileInfoView();
    this.statusBar.addLeftTile({item: this.fileInfo.element, priority: 0});

    this.cursorPosition = new CursorPositionView();
    this.statusBar.addLeftTile({item: this.cursorPosition.element, priority: 1});

    this.selectionCount = new SelectionCountView();
    this.statusBar.addLeftTile({item: this.selectionCount.element, priority: 2});

    this.gitInfo = new GitView();
    return this.gitInfoTile = this.statusBar.addRightTile({item: this.gitInfo.element, priority: 0});
  },

  deactivate() {
    if (this.statusBarVisibilitySubscription != null) {
      this.statusBarVisibilitySubscription.dispose();
    }
    this.statusBarVisibilitySubscription = null;

    if (this.gitInfo != null) {
      this.gitInfo.destroy();
    }
    this.gitInfo = null;

    if (this.fileInfo != null) {
      this.fileInfo.destroy();
    }
    this.fileInfo = null;

    if (this.cursorPosition != null) {
      this.cursorPosition.destroy();
    }
    this.cursorPosition = null;

    if (this.selectionCount != null) {
      this.selectionCount.destroy();
    }
    this.selectionCount = null;

    if (this.statusBarPanel != null) {
      this.statusBarPanel.destroy();
    }
    this.statusBarPanel = null;

    if (this.statusBar != null) {
      this.statusBar.destroy();
    }
    this.statusBar = null;

    if (this.subscriptions != null) {
      this.subscriptions.dispose();
    }
    this.subscriptions = null;

    if (this.emitters != null) {
      this.emitters.dispose();
    }
    this.emitters = null;

    if (atom.__workspaceView != null) { return delete atom.__workspaceView.statusBar; }
  },

  updateStatusBarVisibility() {
    if (atom.config.get('status-bar.isVisible')) {
      return this.statusBarPanel.show();
    } else {
      return this.statusBarPanel.hide();
    }
  },

  provideStatusBar() {
    return {
      addLeftTile: this.statusBar.addLeftTile.bind(this.statusBar),
      addRightTile: this.statusBar.addRightTile.bind(this.statusBar),
      getLeftTiles: this.statusBar.getLeftTiles.bind(this.statusBar),
      getRightTiles: this.statusBar.getRightTiles.bind(this.statusBar),
      disableGitInfoTile: this.gitInfoTile.destroy.bind(this.gitInfoTile)
    };
  },

  attachStatusBar() {
    if (this.statusBarPanel != null) { this.statusBarPanel.destroy(); }

    const panelArgs = {item: this.statusBar, priority: 0};
    if (atom.config.get('status-bar.fullWidth')) {
      return this.statusBarPanel = atom.workspace.addFooterPanel(panelArgs);
    } else {
      return this.statusBarPanel = atom.workspace.addBottomPanel(panelArgs);
    }
  },

  // Deprecated
  //
  // Wrap deprecation calls on the methods returned rather than
  // Services API method which would be registered and trigger
  // a deprecation call
  legacyProvideStatusBar() {
    const statusbar = this.provideStatusBar();

    return {
      addLeftTile(...args) {
        Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.");
        return statusbar.addLeftTile(...Array.from(args || []));
      },
      addRightTile(...args) {
        Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.");
        return statusbar.addRightTile(...Array.from(args || []));
      },
      getLeftTiles() {
        Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.");
        return statusbar.getLeftTiles();
      },
      getRightTiles() {
        Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.");
        return statusbar.getRightTiles();
      }
    };
  }
};
