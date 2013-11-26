{View} = require 'atom'

module.exports =
class StatusBarView extends View
  @content: ->
    @div class: 'status-bar tool-panel panel-bottom', =>
      @div outlet: 'rightPanel', class: 'status-bar-right pull-right'
      @div outlet: 'leftPanel', class: 'status-bar-left'

  initialize: ->
    atom.workspaceView.statusBar = this

    @bufferSubscriptions = []
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', =>
      @unsubscribeAllFromBuffer()
      @storeActiveBuffer()
      @subscribeAllToBuffer()

      @trigger('active-buffer-changed')

    @storeActiveBuffer()

  # Private:
  attach: ->
    atom.workspaceView.vertical.append(this) unless @hasParent()

  # Public:
  appendLeft: (item) ->
    @leftPanel.append(item)

  # Public:
  appendRight: (item) ->
    @rightPanel.append(item)

  # Public:
  getActiveBuffer: ->
    @buffer

  # Public:
  getActiveItem: ->
    atom.workspaceView.getActivePaneItem()

  # Private:
  storeActiveBuffer: ->
    @buffer = @getActiveItem()?.getBuffer?()

  # Public:
  subscribeToBuffer: (event, callback) ->
    @bufferSubscriptions.push([event, callback])
    @buffer.on(event, callback) if @buffer

  # Priavte:
  subscribeAllToBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.on(event, callback)

  # Priavte:
  unsubscribeAllFromBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.off(event, callback)
