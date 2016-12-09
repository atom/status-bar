{Disposable} = require 'atom'

module.exports =
class CursorPositionView
  constructor: ->
    @viewUpdatePending = false

    @element = document.createElement('status-bar-cursor')
    @element.classList.add('cursor-position', 'inline-block')
    @goToLineLink = document.createElement('a')
    @goToLineLink.classList.add('inline-block')
    @goToLineLink.href = '#'
    @element.appendChild(@goToLineLink)

    @formatString = atom.config.get('status-bar.cursorPositionFormat') ? '%L:%C'
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      @subscribeToActiveTextEditor()

    @subscribeToConfig()
    @subscribeToActiveTextEditor()

    @tooltip = atom.tooltips.add(@element, title: => "Line #{@row}, Column #{@column}")

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
    @element.addEventListener('click', clickHandler)
    @clickSubscription = new Disposable => @element.removeEventListener('click', clickHandler)

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
        @element.classList.remove('hide')
      else
        @goToLineLink.textContent = ''
        @element.classList.add('hide')
