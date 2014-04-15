{View} = require 'atom'

module.exports =
class FileInfoView extends View
  @content: ->
    @div class: 'file-info inline-block', =>
      @span class: 'current-path', outlet: 'currentPath'
      @span class: 'buffer-modified', outlet: 'bufferModified'

  initialize: (@statusBar) ->
    @subscribe @statusBar, 'active-buffer-changed', @update
    @statusBar.subscribeToBuffer 'saved modified-status-changed', @update
    @subscribe atom.workspaceView, 'pane:active-item-title-changed', @update

  destroy: ->
    @remove()

  afterAttach: ->
    @updatePathText()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  update: =>
    @updatePathText()
    @updateBufferHasModifiedText(@statusBar.getActiveBuffer()?.isModified())

  updateBufferHasModifiedText: (isModified) ->
    if isModified
      @bufferModified.text('*') unless @isModified
      @isModified = true
    else
      @bufferModified.text('') if @isModified
      @isModified = false

  updatePathText: ->
    if path = @getActiveItem()?.getPath?()
      @currentPath.text(atom.project.relativize(path)).show()
    else if title = @getActiveItem()?.getTitle?()
      @currentPath.text(title).show()
    else
      @currentPath.hide()
