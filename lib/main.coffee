Grim = require 'grim'
StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
SelectionCountView = require './selection-count-view'
GitView = require './git-view'

module.exports =
  activate: ->
    @statusBar = new StatusBarView()
    @statusBar.initialize()
    @statusBarPanel = atom.workspace.addBottomPanel(item: @statusBar, priority: 0)

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

  provideStatusBar: ->
    addLeftTile: @statusBar.addLeftTile.bind(@statusBar)
    addRightTile: @statusBar.addRightTile.bind(@statusBar)
    getLeftTiles: @statusBar.getLeftTiles.bind(@statusBar)
    getRightTiles: @statusBar.getRightTiles.bind(@statusBar)

  # Depreciated
  #
  # Wrap deprecation calls on the methods returned rather than
  # Services API method which would be registered and trigger
  # a deprecation call
  legacyProvideStatusBar: ->
    statusbar = @provideStatusBar()

    addLeftTile: (args...) ->
      Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.")
      statusbar.addLeftTile(args...)
    addRightTile: (args...) ->
      Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.")
      statusbar.addRightTile(args...)
    getLeftTiles: ->
      Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.")
      statusbar.getLeftTiles()
    getRightTiles: ->
      Grim.deprecate("Use version ^1.0.0 of the status-bar Service API.")
      statusbar.getRightTiles()
