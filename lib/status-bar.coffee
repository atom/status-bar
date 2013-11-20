StatusBarView = require './status-bar-view'

module.exports =
  activate: ->
    @statusBarView = new StatusBarView()
    @statusBarView.attach()
