{Disposable} = require 'atom'

class CursorPositionView extends HTMLElement
  initialize: ->
    @viewUpdatePending = false

    @classList.add('cursor-position', 'inline-block')
    @goToLineLink = document.createElement('a')
    @goToLineLink.classList.add('inline-block')
    @goToLineLink.href = '#'
    @appendChild(@goToLineLink)

    @formatString = atom.config.get('status-bar.cursorPositionFormat') ? '%L:%C'
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToConfig()
    @subscribeToActiveTextEditor()

    @tooltip = atom.tooltips.add(this, title: ->
      "Line #{@row}, Column #{@column}")

    @handleClick()

  destroy: ->
    @activeItemSubscription.dispose()
    @cursorSubscription?.dispose()
    @tooltip.dispose()
    @configSubscription?.dispose()
    @clickSubscription.dispose()
    @updateSubscription?.dispose()

  subscribeToActiveTextEditor: ->
    @cursorSubscription?.dispose()
    activeEditor = @getActiveTextEditor()
    @cursorSubscription = activeEditor?.onDidChangeCursorPosition ({cursor}) =>
      return unless cursor is activeEditor.getLastCursor()
      @updatePosition()
    @updatePosition()

  subscribeToConfig: ->
    @configSubscription?.dispose()
    @configSubscription = atom.config.observe 'status-bar.cursorPositionFormat', (value) =>
      @formatString = value ? '%L:%C'
      @updatePosition()

  handleClick: ->
    clickHandler = => atom.commands.dispatch(atom.views.getView(@getActiveTextEditor()), 'go-to-line:toggle')
    @addEventListener('click', clickHandler)
    @clickSubscription = new Disposable => @removeEventListener('click', clickHandler)

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updatePosition: ->
    return if @viewUpdatePending

    @viewUpdatePending = true
    @updateSubscription = atom.views.updateDocument =>
      @viewUpdatePending = false
      if position = @getActiveTextEditor()?.getCursorBufferPosition()
        @row = position.row + 1
        @column = position.column + 1
        @goToLineLink.textContent = @formatString.replace('%L', @row).replace('%C', @column)
        @classList.remove('hide')
      else
        @goToLineLink.textContent = ''
        @classList.add('hide')

module.exports = document.registerElement('status-bar-cursor', prototype: CursorPositionView.prototype, extends: 'div')
