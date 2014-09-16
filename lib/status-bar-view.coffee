{$} = require 'atom'

class StatusBarView extends HTMLElement
  initialize: (state) ->
    @classList.add('status-bar', 'tool-panel', 'panel-bottom')

    flexboxHackElement = document.createElement('div')
    flexboxHackElement.classList.add('flexbox-repaint-hack')
    @appendChild(flexboxHackElement)

    @rightPanel = document.createElement('div')
    @rightPanel.classList.add('status-bar-right', 'pull-right')
    flexboxHackElement.appendChild(@rightPanel)

    @leftPanel = document.createElement('div')
    @leftPanel.classList.add('status-bar-left')
    flexboxHackElement.appendChild(@leftPanel)

    @bufferSubscriptions = []

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @unsubscribeAllFromBuffer()
      @storeActiveBuffer()
      @subscribeAllToBuffer()

      @dispatchEvent(new CustomEvent('active-buffer-changed', bubbles: true))

    @storeActiveBuffer()

    @attach() if state.attached

  serialize: ->
    attached: @parentElement?

  attach: ->
    atom.workspaceView.appendToBottom(this) unless @parentElement?

  destroy: ->
    @activeItemSubscription.dispose()
    @unsubscribeAllFromBuffer()
    @remove()

  toggle: ->
    if @parentElement
      @remove()
    else
      @attach()

  # Public: Append the view to the left side of the status bar.
  appendLeft: (view) ->
    $(@leftPanel).append(view)

  # Public: Prepend the view to the left side of the status bar.
  prependLeft: (view) ->
    $(@leftPanel).prepend(view)

  # Public: Append the view to the right side of the status bar.
  appendRight: (view) ->
    $(@rightPanel).append(view)

  # Public: Prepend the view to the right side of the status bar.
  prependRight: (view) ->
    $(@rightPanel).prepend(view)

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

module.exports = document.registerElement('status-bar', prototype: StatusBarView.prototype, extends: 'div')
