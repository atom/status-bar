{SelectListView} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
branches = []
module.exports =
class BranchListView extends SelectListView
  initialize: ->
    super

    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('branch-selector')
    @list.addClass('mark-active')



  setRepository: (@repo) ->
    console.log(@repo)
    command = "git"
    options = {}
    options.cwd = @repo.getWorkingDirectory()
    stderr = (data) -> console.error data.toString()
    stdout = (data) ->
      branches = []
      for branch in data.toString().split('\n')
        if branch.length > 0
          name = branch.split("/").reverse()[0]
          remote = branch.indexOf("remotes/") >= 0
          current = branch.startsWith("* ")
          name = name.replace("* ", "")
          branches.push({name: name, remote: remote, current: current})
      console.log(branches)
    exit = (exit) ->
      console.log @save ?= ''
      @save = null
    args = ['branch']

    try
      new BufferedProcess
        command: command
        args: args
        options: options
        stdout: stdout
        stderr: stderr
        exit: exit
    catch error
      console.error('Git Plus is unable to locate git command. Please ensure process.env.PATH can access git.')

  getFilterKey: ->
    'name'

  git: (args) ->
    command = "git"
    options = {}
    options.cwd = @repo.getWorkingDirectory()
    stderr = (data) -> console.error data.toString()
    stdout = (data) -> console.log data.toString()
    exit = (exit) ->
      console.log exit
    try
      new BufferedProcess
        command: command
        args: args
        options: options
        stdout: stdout
        stderr: stderr
        exit: exit
    catch error
      console.error('Git Plus is unable to locate git command. Please ensure process.env.PATH can access git.')

  addBranches: ->
    @setItems(branches)

  viewForItem: (branch) ->
    element = document.createElement('li')
    element.classList.add('active') if branch.current
    element.textContent = branch.name
    element

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @attach()

  destroy: ->
    @panel.destroy()

  cancelled: ->
    @panel.hide()

  confirmed: (branch) ->
    @cancel()
    @git(['checkout',branch.name])

  addEncodings: ->
    @currentEncoding = @editor.getEncoding()
    encodingItems = []

    if fs.existsSync(@editor.getPath())
      encodingItems.push({id: 'detect', name: 'Auto Detect'})

    for id, names of @encodings
      encodingItems.push({id, name: names.list})
    @setItems(encodingItems)

  attach: ->
    @storeFocusedElement()
    @addBranches()
    @panel.show()
    @focusFilterEditor()
