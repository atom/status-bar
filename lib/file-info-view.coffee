{Disposable} = require 'atom'
url = require 'url'

class FileInfoView extends HTMLElement
  initialize: ->
    @classList.add('file-info', 'inline-block')

    @currentPath = document.createElement('a')
    @currentPath.classList.add('current-path')
    @appendChild(@currentPath)

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @subscribeToActiveItem()

    clickHandler = (event) =>
      isShiftClick = event.shiftKey
      @showCopiedTooltip(isShiftClick)
      text = @getActiveItemCopyText(isShiftClick)
      atom.clipboard.write(text)
      setTimeout =>
        @clearCopiedTooltip()
      , 2000

    @currentPath.addEventListener('click', clickHandler)
    @clickSubscription = new Disposable => @removeEventListener('click', clickHandler)

  clearCopiedTooltip: ->
    @copiedTooltip?.dispose()

  showCopiedTooltip: (isShiftClick) ->
    @copiedTooltip?.dispose()
    text = @getActiveItemCopyText(isShiftClick)
    @copiedTooltip = atom.tooltips.add this,
      title: "Copied: #{text}"
      trigger: 'click'
      delay:
        show: 0

  getActiveItemCopyText: (isShiftClick) ->
    activeItem = @getActiveItem()
    # An item path could be a url, but we only want to copy the `path` part of it.
    path = url.parse(activeItem?.getPath?() or '').path or activeItem?.getTitle?() or ''

    if isShiftClick
      atom.project.relativize(path)
    else
      path

  subscribeToActiveItem: ->
    @modifiedSubscription?.dispose()
    @titleSubscription?.dispose()

    if activeItem = @getActiveItem()
      @updateCallback ?= => @update()

      if typeof activeItem.onDidChangeTitle is 'function'
        @titleSubscription = activeItem.onDidChangeTitle(@updateCallback)
      else if typeof activeItem.on is 'function'
        #TODO Remove once title-changed event support is removed
        activeItem.on('title-changed', @updateCallback)
        @titleSubscription = dispose: =>
          activeItem.off?('title-changed', @updateCallback)

      @modifiedSubscription = activeItem.onDidChangeModified?(@updateCallback)

    @update()

  destroy: ->
    @activeItemSubscription.dispose()
    @titleSubscription?.dispose()
    @modifiedSubscription?.dispose()
    @clickSubscription?.dispose()
    @copiedTooltip?.dispose()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  update: ->
    @updatePathText()
    @updateBufferHasModifiedText(@getActiveItem()?.isModified?())

  updateBufferHasModifiedText: (isModified) ->
    if isModified
      @classList.add('buffer-modified')
      @isModified = true
    else
      @classList.remove('buffer-modified')
      @isModified = false

  updatePathText: ->
    if path = @getActiveItem()?.getPath?()
      @currentPath.textContent = atom.project.relativize(path)
    else if title = @getActiveItem()?.getTitle?()
      @currentPath.textContent = title
    else
      @currentPath.textContent = ''

module.exports = document.registerElement('status-bar-file', prototype: FileInfoView.prototype, extends: 'div')
