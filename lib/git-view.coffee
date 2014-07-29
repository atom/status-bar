{View} = require 'atom'

module.exports =
class GitView extends View
  @content: ->
    @div class: 'git-view inline-block', =>
      @div class: 'git-branch inline-block', outlet: 'branchArea', =>
        @span class: 'icon icon-git-branch'
        @span class: 'branch-label', outlet: 'branchLabel'
      @div class: 'git-commits inline-block', outlet: 'commitsArea', =>
        @span class: 'icon icon-arrow-up commits-ahead-label', outlet: 'commitsAhead'
        @span class: 'icon icon-arrow-down commits-behind-label', outlet: 'commitsBehind'
      @div class: 'git-status inline-block', outlet: 'gitStatus', =>
        @span outlet: 'gitStatusIcon'

  initialize: (@statusBar) ->
    @statusBar.subscribeToBuffer 'saved', @update
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', @update
    @subscribe atom.project, 'path-changed', @subscribeToRepo
    @subscribeToRepo()

  destroy: ->
    @unsubscribe(@repo) if @repo?
    @repo = null
    @remove()

  afterAttach: ->
    @update()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  getActiveView: ->
    atom.workspaceView.getActiveView()

  subscribeToRepo: =>
    @unsubscribe(@repo) if @repo?
    if repo = atom.project.getRepo()
      @repo = repo
      @subscribe repo, 'status-changed', (path, status) =>
        @update() if path is @getActiveItemPath()
      @subscribe repo, 'statuses-changed', @update

  update: =>
    @updateBranchText()
    @updateStatusText()

  updateBranchText: ->
    @branchArea.hide()
    if @showBranchInformation()
      head = atom.project.getRepo()?.getShortHead(@getActiveItemPath()) or ''
      @branchLabel.text(head)
      @branchArea.show() if head

  showBranchInformation: ->
    if itemPath = @getActiveItemPath()
      atom.project.contains(itemPath)
    else
      not @getActiveItem()?

  updateStatusText: ->
    itemPath = @getActiveItemPath()
    @gitStatus.hide()
    @commitsArea.hide()

    repo = atom.project.getRepo()
    return unless repo?

    if @showBranchInformation()
      {ahead, behind} = repo.getCachedUpstreamAheadBehindCount(itemPath) ? {}

      if ahead > 0
        @commitsAhead.text(ahead).show()
      else
        @commitsAhead.hide()

      if behind > 0
        @commitsBehind.text(behind).show()
      else
        @commitsBehind.hide()

      @commitsArea.show() if ahead > 0 or behind > 0

    status = repo.getCachedPathStatus(itemPath) ? 0
    @gitStatusIcon.removeClass()
    if repo.isStatusModified(status)
      @gitStatusIcon.addClass('icon icon-diff-modified status-modified')
      stats = repo.getDiffStats(itemPath)
      if stats.added and stats.deleted
        @gitStatusIcon.text("+#{stats.added}, -#{stats.deleted}")
      else if stats.added
        @gitStatusIcon.text("+#{stats.added}")
      else if stats.deleted
        @gitStatusIcon.text("-#{stats.deleted}")
      else
        @gitStatusIcon.text('')
    else if repo.isStatusNew(status)
      @gitStatusIcon.addClass('icon icon-diff-added status-added')
      if @statusBar.getActiveBuffer()?
        @gitStatusIcon.text("+#{@statusBar.getActiveBuffer().getLineCount()}")
      else
        @gitStatusIcon.text('')
    else if repo.isPathIgnored(itemPath)
      @gitStatusIcon.addClass('icon icon-diff-ignored status-ignored')
      @gitStatusIcon.text('')

    if @gitStatusIcon.attr('class') then @gitStatus.show() else @gitStatus.hide()
