{SelectListView} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
{Emitter} = require 'atom'
branches = []
emitter = null
module.exports =
class BranchListView extends SelectListView
  initialize: ->
    super

    emitter = new Emitter
    emitter.on 'on-change-branch', (branch) ->
      atom.workspace.getActivePaneItem().save()
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('branch-selector')
    @list.addClass('mark-active')



  setRepository: (@repo) ->
    git
      cwd: @repo.getWorkingDirectory()
      args: ["branch", "-a"]
      stdout: (data) ->
        branches = []
        for branch in data.toString().split('\n')
          if branch.length > 0
            full = branch.replace("* ", "").trim()
            name = full.replace("remotes/","")
            remote = branch.includes("remotes/")
            current = branch.startsWith("* ")
            unless full.includes("->")
              branches.push({name: name, remote: remote, current: current, full: full})

  getFilterKey: ->
    'name'

  git = ({args, cwd, options, stdout, stderr, exit}={}) ->
    command = "git"
    options ?= {}
    options.cwd ?= cwd
    stderr ?= (data) ->
      console.error(data.toString())
      @error = data.toString()
    stdout ?= (data) -> console.log data.toString()
    exit ?= (exit) ->
      console.log(exit)
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
    # element.textContent = branch.name
    element.innerHTML = branch.name
    console.log(element)
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
    cwd = @repo.getWorkingDirectory()
    git
      args: ["checkout", branch.full]
      cwd: cwd
      stderr: (data) ->
        console.log(data.toString())
        @error = data.toString()
      exit: (data) ->
        code = parseInt(data)
        if code != 0
          if @error.includes("error: Your local changes to the following files would be overwritten by checkout:")
            options=
              detail: "You must stash or commit your changes before attempting\n to checkout a new branch"
              buttons:
                [{text: 'Checkout Anyways',
                onDidClick: ->
                  git
                    args: ['stash']
                    cwd: cwd
                    exit: (code) ->
                      git
                        args: ['checkout',branch.full]
                        cwd: cwd
                  emitter.emit 'on-change-branch', branch.name}]
              dismissable: true
            notification = atom.notifications.addError("You have uncommitted changes", options)
        if code == 0
          emitter.emit 'on-change-branch', branch.name
  attach: ->
    @storeFocusedElement()
    @addBranches()
    @panel.show()
    @focusFilterEditor()

  onChangeBranch: (callback) ->
    emitter.on 'on-change-branch', callback
