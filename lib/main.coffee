{$} = require 'atom'
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
    @statusBarPanel = atom.workspace.addBottomPanel(item: @statusBar)

    # Wrap status bar element in a jQuery wrapper for backwards compatibility
    wrappedStatusBar = $(@statusBar)
    wrappedStatusBar.appendLeft        = (view) => @statusBar.appendLeft(view)
    wrappedStatusBar.appendRight       = (view) => @statusBar.appendRight(view)
    wrappedStatusBar.prependLeft       = (view) => @statusBar.prependLeft(view)
    wrappedStatusBar.prependRight      = (view) => @statusBar.prependRight(view)
    wrappedStatusBar.getActiveBuffer   = => @statusBar.getActiveBuffer()
    wrappedStatusBar.getActiveItem     = => @statusBar.getActiveItem()
    wrappedStatusBar.subscribeToBuffer = (event, callback) => @statusBar.subscribeToBuffer(event, callback)
    atom.workspaceView.statusBar = wrappedStatusBar

    atom.workspaceView.command 'status-bar:toggle', =>
      if @statusBarPanel.isVisible()
        @statusBarPanel.hide()
      else
        @statusBarPanel.show()

    if atom.getLoadSettings().devMode
      DevModeView = require './dev-mode-view'
      devModeView = new DevModeView()
      devModeView.initialize()
      @statusBar.appendLeft(devModeView)

    @fileInfo = new FileInfoView()
    @fileInfo.initialize()
    @statusBar.appendLeft(@fileInfo)

    @cursorPosition = new CursorPositionView()
    @cursorPosition.initialize()
    @statusBar.appendLeft(@cursorPosition)

    @selectionCount = new SelectionCountView()
    @selectionCount.initialize()
    @statusBar.appendLeft(@selectionCount)

    @git = new GitView()
    @git.initialize()
    @statusBar.appendRight(@git)

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
    @statusBarPanel

    @statusBar?.destroy()
    @statusBar = null

    atom.workspaceView.statusBar = null
