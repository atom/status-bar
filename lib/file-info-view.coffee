{Disposable} = require 'atom'

class FileInfoView extends HTMLElement
  initialize: ->
    @classList.add('file-info', 'inline-block')

    @currentPath = document.createElement('a')
    @currentPath.classList.add('current-path')
    @appendChild(@currentPath)

    @bufferModified = document.createElement('span')
    @bufferModified.classList.add('buffer-modified')
    @appendChild(@bufferModified)

    @handleCopiedTooltip()

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @subscribeToActiveItem()

    clickHandler = =>
      text = @getActiveItem()?.getPath?() or @getActiveItem()?.getTitle?() or ''
      atom.clipboard.write(text)
      setTimeout =>
        @handleCopiedTooltip()
      , 2000

    @currentPath.addEventListener('click', clickHandler)
    @clickSubscription = new Disposable => @removeEventListener('click', clickHandler)

  handleCopiedTooltip: ->
    @copiedTooltip?.dispose()
    text = @getActiveItem()?.getPath?() or @getActiveItem()?.getTitle?() or ''
    @copiedTooltip = atom.tooltips.add this,
      title: "Copied: #{text}"
      trigger: 'click'
      delay:
        show: 0

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
    @handleCopiedTooltip()
    @updateBufferHasModifiedText(@getActiveItem()?.isModified?())

  updateBufferHasModifiedText: (isModified) ->
    if isModified
      @bufferModified.textContent = '*' unless @isModified
      @isModified = true
    else
      @bufferModified.textContent = '' if @isModified
      @isModified = false

  updatePathText: ->
    if path = @getActiveItem()?.getPath?()
      @currentPath.textContent = atom.project.relativize(path)
    else if title = @getActiveItem()?.getTitle?()
      @currentPath.textContent = title
    else
      @currentPath.textContent = ''

module.exports = document.registerElement('status-bar-file', prototype: FileInfoView.prototype, extends: 'div')
