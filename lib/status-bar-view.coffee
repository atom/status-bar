{$} = require 'space-pen'

class StatusBarView extends HTMLElement
  createdCallback: ->
    @classList.add('status-bar')

    flexboxHackElement = document.createElement('div')
    flexboxHackElement.classList.add('flexbox-repaint-hack')
    @appendChild(flexboxHackElement)

    @rightPanel = document.createElement('div')
    @rightPanel.classList.add('status-bar-right', 'pull-right')
    flexboxHackElement.appendChild(@rightPanel)

    @leftPanel = document.createElement('div')
    @leftPanel.classList.add('status-bar-left')
    flexboxHackElement.appendChild(@leftPanel)

    @leftItems = []
    @rightItems = []

  initialize: (state) ->
    @bufferSubscriptions = []

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @unsubscribeAllFromBuffer()
      @storeActiveBuffer()
      @subscribeAllToBuffer()

      @dispatchEvent(new CustomEvent('active-buffer-changed', bubbles: true))

    @storeActiveBuffer()
    this

  destroy: ->
    @activeItemSubscription.dispose()
    @unsubscribeAllFromBuffer()
    @remove()

  addLeftItem: (newItem, options) ->
    newPriority = options?.priority ? @leftItems[@leftItems.length - 1].priority + 1
    nextItem = null
    for {priority, item}, index in @leftItems
      if priority > newPriority
        nextItem = item
        break

    @leftItems.splice(index, 0, {item: newItem, priority: newPriority})
    newElement = atom.views.getView(newItem)
    nextElement = atom.views.getView(nextItem)
    @leftPanel.insertBefore(newElement, nextElement)

  addRightItem: (newItem, options) ->
    newPriority = options?.priority ? @rightItems[0].priority + 1
    nextItem = null
    for {priority, item}, index in @rightItems
      if priority < newPriority
        nextItem = item
        break

    @rightItems.splice(index, 0, {item: newItem, priority: newPriority})
    newElement = atom.views.getView(newItem)
    nextElement = atom.views.getView(nextItem)
    @rightPanel.insertBefore(newElement, nextElement)

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

module.exports = document.registerElement('status-bar', prototype: StatusBarView.prototype)
