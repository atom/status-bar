{View} = require 'atom'

module.exports =
class StatusBarView extends View
  @content: ->
    @div class: 'status-bar tool-panel panel-bottom', =>
      @div class: 'flexbox-repaint-hack', =>
        @div outlet: 'rightPanel', class: 'status-bar-right pull-right'
        @div outlet: 'leftPanel', class: 'status-bar-left'

  serialize: ->
    attached: @hasParent()

  initialize: (state) ->
    atom.workspaceView.statusBar = this

    @bufferSubscriptions = []
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', =>
      @unsubscribeAllFromBuffer()
      @storeActiveBuffer()
      @subscribeAllToBuffer()

      @trigger('active-buffer-changed')

    @storeActiveBuffer()

    @attach() if state.attached

  attach: ->
    atom.workspaceView.appendToBottom(this) unless @hasParent()

  destroy: ->
    @remove()
    atom.workspaceView.statusBar = null

  toggle: ->
    if @hasParent()
      @detach()
    else
      @attach()

  # Public: Append the view to the left side of the status bar.
  appendLeft: (view) ->
    @leftPanel.append(view)

  # Public: Prepend the view to the left side of the status bar.
  prependLeft: (view) ->
    @leftPanel.prepend(view)

  # Public: Append the view to the right side of the status bar.
  appendRight: (view) ->
    @rightPanel.append(view)

  # Public: Prepend the view to the right side of the status bar.
  prependRight: (view) ->
    @rightPanel.prepend(view)

  # Public:
  getActiveBuffer: ->
    @buffer

  # Public:
  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  storeActiveBuffer: ->
    @buffer = @getActiveItem()?.getBuffer?()

  # Public:
  subscribeToBuffer: (event, callback) ->
    @bufferSubscriptions.push([event, callback])
    @buffer.on(event, callback) if @buffer

  subscribeAllToBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.on(event, callback)

  unsubscribeAllFromBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.off(event, callback)
