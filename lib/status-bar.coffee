StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
GitView = require './git-view'

module.exports =
  activate: ->
    @statusBar = new StatusBarView()
    @statusBar.attach()

    if atom.getLoadSettings().devMode
      DevModeView = require './dev-mode-view'
      @statusBar.appendLeft(new DevModeView())

    @fileInfo = new FileInfoView(@statusBar)
    @statusBar.appendLeft(@fileInfo)

    @cursorPosition = new CursorPositionView(@statusBar)
    @statusBar.appendLeft(@cursorPosition)

    @git = new GitView(@statusBar)
    @statusBar.appendRight(@git)

  deactivate: ->
    @git?.destroy()
    @git = null

    @fileInfo?.destroy()
    @fileInfo = null

    @cursorPosition?.destroy()
    @cursorPosition = null

    @statusBar?.destroy()
    @statusBar = null
