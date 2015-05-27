Grim = require 'grim'
StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
SelectionCountView = require './selection-count-view'
GitView = require './git-view'

module.exports =
  config:
    cursorPositionFormat:
      type: 'string'
      default: '%L:%C'
      description: 'Format for the cursor position status bar element, where %L is the line number and %C is the column number'

  activate: ->
    @statusBar = new StatusBarView()
    @statusBar.initialize()
    @statusBarPanel = atom.workspace.addBottomPanel(item: @statusBar, priority: 0)

    if Grim.includeDeprecatedAPIs
      {$} = require 'atom-space-pen-views'
      # Wrap status bar element in a jQuery wrapper for backwards compatibility
      wrappedStatusBar = $.extend $(@statusBar),
        appendLeft: (view) =>
          Grim.deprecate("Use ::addLeftTile({item, priority}) instead.")
          @statusBar.appendLeft(view)

        appendRight: (view) =>
          Grim.deprecate("Use ::addRightTile({item, priority}) instead.")
          @statusBar.appendRight(view)

        prependLeft: (view) =>
          Grim.deprecate("Use ::addLeftTile({item, priority}) instead.")
          @statusBar.prependLeft(view)

        prependRight: (view) =>
          Grim.deprecate("Use ::addRightTile({item, priority}) instead.")
          @statusBar.prependRight(view)

        getActiveBuffer: =>
          Grim.deprecate("Use atom.workspace.getActiveTextEditor() instead.")
          @statusBar.getActiveBuffer()

        getActiveItem: =>
          Grim.deprecate("Use atom.workspace.getActivePaneItem() instead.")
          @statusBar.getActiveItem()

        subscribeToBuffer: (event, callback) =>
          Grim.deprecate("Subscribe to TextEditor events instead.")
          @statusBar.subscribeToBuffer(event, callback)

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
