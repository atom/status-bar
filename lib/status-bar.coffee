StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
GitView = require './git-view'

module.exports =
  activate: ->
    @statusBar = new StatusBarView()
    @statusBar.attach()

    @fileInfo = new FileInfoView(@statusBar)
    @statusBar.appendLeft(@fileInfo)

    @cursorPosition = new CursorPositionView(@statusBar)
    @statusBar.appendLeft(@cursorPosition)

    @git = new GitView(@statusBar)
    @statusBar.appendRight(@git)
