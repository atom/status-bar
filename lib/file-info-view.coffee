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

    @newTooltip()

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @subscribeToActiveItem()

    clickHandler = ->
      atom.clipboard.write(@getActiveItem()?.getPath?() or 'untitled')
      setTimeout =>
        @newTooltip()
      , 2000

    @addEventListener('click', clickHandler)
    @clickSubscription = new Disposable => @removeEventListener('click', clickHandler)

  newTooltip: ->
    @myTip?.dispose()
    @myTip = atom.tooltips.add this,
      title: 'Copied: '+(@getActiveItem()?.getPath?() or 'untitled')
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
    @myTip?.dispose()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  update: ->
    @updatePathText()
    @newTooltip()
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
