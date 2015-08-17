{Disposable} = require 'atom'

# View to show the grammar name in the status bar.
class IndentationStatusView extends HTMLDivElement
  initialize: (@statusBar) ->
    @classList.add('indentation-status', 'inline-block')

    @icon = document.createElement('span')
    @icon.classList.add('inline-block')
    @icon.style.marginRight = '5px'
    @icon.textContent = '»'

    @tabTypeLink = document.createElement('a')
    @tabTypeLink.classList.add('inline-block', 'tabtype-selector')
    @tabTypeLink.style.marginRight = '5px'
    @tabTypeLink.href = '#'

    @tabLengthLink = document.createElement('a')
    @tabLengthLink.classList.add('inline-block', 'tabwidth-selector')
    @tabLengthLink.href = '#'

    @appendChild(@icon)
    @appendChild(@tabTypeLink)
    @appendChild(@tabLengthLink)
    @handleEvents()
    this

  handleEvents: ->
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToPotentialEvents()

    @tabTypeLink.addEventListener('click', @tabTypeToggle.bind(this))
    @tabLengthLink.addEventListener('click', @tabWidthToggle.bind(this))

    @tabTypeLinkClickSubscription = new Disposable => @tabTypeLink.removeEventListener('click', @tabTypeToggle)
    @tabLengthLinkClickSubscription = new Disposable => @tabLengthLink.removeEventListener('click', @tabWidthToggle)

    @subscribeToPotentialEvents()

  destroy: ->
    @activeItemSubscription?.dispose()
    @userChangeSubscription?.dispose()
    @tabTypeLinkClickSubscription?.dispose()
    @tabLengthLinkClickSubscription?.dispose()
    @configSubscription?.dispose()
    @indentationConfigSubscription?.dispose()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  tabTypeToggle: (ev) ->
    editor = @getActiveTextEditor()
    # Get current value
    softTabs = editor.getSoftTabs(editor.getRootScopeDescriptor())
    # Toggle softTabs
    editor.setSoftTabs(not softTabs, editor.getRootScopeDescriptor())
    # console.log 'toggle softTabs to ' + (not softTabs)
    # console.log 'now it is ' + editor.getSoftTabs()

    # Update interface
    @updateTabTypeText()

  tabWidthToggle: (ev) ->
    editor = @getActiveTextEditor()

    tabWidth = editor.getTabLength(scope: editor.getRootScopeDescriptor())

    # Iterate over fixed options
    tabWidth += 2
    if tabWidth > 8
      tabWidth = 2

    editor.setTabLength(tabWidth)
    @updateTabWidthText()

  subscribeToPotentialEvents: ->
    @userChangeSubscription?.dispose()
    @indentationConfigSubscription?.dispose()
    @indentationConfigSubscription = atom.config.observe 'editor.tabType', =>
      @updateTabTypeText()
    # FIXME: Noisy channel subscription, change to better one
    @userChangeSubscription = @getActiveTextEditor()?.onDidChange =>
      @updateIndentationText()
    @updateIndentationText()

  updateIndentationText: ->
    @updateTabTypeText()
    @updateTabWidthText()

  updateTabTypeText: ->
    softTabs = @getActiveTextEditor()?.getSoftTabs()
    @tabTypeLink.textContent = 'tab'
    @tabTypeLink.textContent = 'space' if softTabs

  updateTabWidthText: ->
    tabwidth = @getActiveTextEditor()?.getTabLength()
    # console.log 'update to ' + tabwidth
    @tabLengthLink.textContent = tabwidth

module.exports = document.registerElement('indentation-status', prototype: IndentationStatusView.prototype)
