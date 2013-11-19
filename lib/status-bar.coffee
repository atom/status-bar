StatusBarView = require './status-bar-view'
FileInfoView = require './file-info-view'

module.exports =
  activate: ->
    @statusBarView = new StatusBarView()
    @statusBarView.attach()

    @fileInfo = new FileInfoView(@statusBarView)
    @statusBarView.appendLeft(@fileInfo)
