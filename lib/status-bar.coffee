StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'
CursorPositionView = require './cursor-position-view'
GrammarView = require './grammar-view'
GitView = require './git-view'

module.exports =
  activate: ->
    @statusBar = new StatusBarView()
    @statusBar.attach()

    @fileInfo = new FileInfoView(@statusBar)
    @statusBar.appendLeft(@fileInfo)

    @cursorPosition = new CursorPositionView(@statusBar)
    @statusBar.appendLeft(@cursorPosition)

    @grammar = new GrammarView(@statusBar)
    @statusBar.appendLeft(@grammar)

    @git = new GitView(@statusBar)
    @statusBar.appendRight(@git)
