{$} = require 'space-pen'
Grim = require 'grim'
StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
SelectionCountView = require './selection-count-view'
GitView = require './git-view'

module.exports =
  activate: (state = {}) ->
    state.attached ?= true

    @statusBar = new StatusBarView()
    @statusBar.initialize(state)
    @statusBarPanel = atom.workspace.addBottomPanel(item: @statusBar, priority: 0)

    # Remove when legacy panel classes PR (atom/atom#4305) has been released
    atom.views.getView(@statusBarPanel).classList.add("tool-panel", "panel-bottom")

    # Wrap status bar element in a jQuery wrapper for backwards compatibility
    wrappedStatusBar = $.extend $(@statusBar),
      appendLeft: (view) => @statusBar.appendLeft(view)
      appendRight: (view) => @statusBar.appendRight(view)
      prependLeft: (view) => @statusBar.prependLeft(view)
      prependRight: (view) => @statusBar.prependRight(view)
      getActiveBuffer: => @statusBar.getActiveBuffer()
      getActiveItem: => @statusBar.getActiveItem()
      subscribeToBuffer: (event, callback) => @statusBar.subscribeToBuffer(event, callback)

    if atom.__workspaceView?
      Object.defineProperty atom.__workspaceView, 'statusBar',
        get: ->
          Grim.deprecate """
            The atom.workspaceView.statusBar global is deprecated. The global was
            previously being assigned by the status-bar package, but Atom packages
            should never assign globals.

            In the future, this problem will be solved by an inter-package communication
            API available on `atom.services`. For now, you can get a reference to the
            `status-bar` element via `document.querySelector('status-bar')`.
          """
          wrappedStatusBar
        configurable: true

    atom.commands.add 'atom-workspace', 'status-bar:toggle', =>
      if @statusBarPanel.isVisible()
        @statusBarPanel.hide()
      else
        @statusBarPanel.show()

    {safeMode, devMode} = atom.getLoadSettings()
    if safeMode or devMode
      LaunchModeView = require './launch-mode-view'
      launchModeView = new LaunchModeView()
      launchModeView.initialize({safeMode, devMode})
      @statusBar.addLeftTile(item: launchModeView, priority: -1)

    @fileInfo = new FileInfoView()
    @fileInfo.initialize()
    @statusBar.addLeftTile(item: @fileInfo, priority: 0)

    @cursorPosition = new CursorPositionView()
    @cursorPosition.initialize()
    @statusBar.addLeftTile(item: @cursorPosition, priority: 1)

    @selectionCount = new SelectionCountView()
    @selectionCount.initialize()
    @statusBar.addLeftTile(item: @selectionCount, priority: 2)

    @git = new GitView()
    @git.initialize()
    @statusBar.addRightTile(item: @git, priority: 0)

  deactivate: ->
    @git?.destroy()
    @git = null

    @fileInfo?.destroy()
    @fileInfo = null

    @cursorPosition?.destroy()
    @cursorPosition = null

    @selectionCount?.destroy()
    @selectionCount = null

    @statusBarPanel?.destroy()
    @statusBarPanel = null

    @statusBar?.destroy()
    @statusBar = null

    delete atom.__workspaceView.statusBar if atom.__workspaceView?
