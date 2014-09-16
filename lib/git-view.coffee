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
        @span outlet: 'gitStatusIcon', class: 'icon'

  initialize: (@statusBar) ->
    @branchArea = @branchArea.element
    @branchLabel = @branchLabel.element
    @commitsArea = @commitsArea.element
    @commitsAhead = @commitsAhead.element
    @commitsBehind = @commitsBehind.element
    @gitStatus = @gitStatus.element
    @gitStatusIcon = @gitStatusIcon.element

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
    @branchArea.style.display = 'none'
    if @showBranchInformation()
      head = atom.project.getRepo()?.getShortHead(@getActiveItemPath()) or ''
      @branchLabel.textContent = head
      @branchArea.style.display = '' if head

  showBranchInformation: ->
    if itemPath = @getActiveItemPath()
      atom.project.contains(itemPath)
    else
      not @getActiveItem()?

  updateStatusText: ->
    itemPath = @getActiveItemPath()
    @gitStatus.style.display = 'none'
    @commitsArea.style.display = 'none'

    repo = atom.project.getRepo()
    return unless repo?

    if @showBranchInformation()
      {ahead, behind} = repo.getCachedUpstreamAheadBehindCount(itemPath) ? {}

      if ahead > 0
        @commitsAhead.textContent = ahead
        @commitsAhead.style.display = ''
      else
        @commitsAhead.style.display = 'none'

      if behind > 0
        @commitsBehind.textContent = behind
        @commitsBehind.style.display = ''
      else
        @commitsBehind.style.display = 'none'

      @commitsArea.style.display = '' if ahead > 0 or behind > 0

    status = repo.getCachedPathStatus(itemPath) ? 0
    @gitStatusIcon.classList.remove('icon-diff-modified', 'status-modified', 'icon-diff-added', 'status-added', 'icon-diff-ignored', 'status-ignored')

    if repo.isStatusModified(status)
      @gitStatusIcon.classList.add('icon-diff-modified', 'status-modified')
      stats = repo.getDiffStats(itemPath)
      if stats.added and stats.deleted
        @gitStatusIcon.textContent = "+#{stats.added}, -#{stats.deleted}"
      else if stats.added
        @gitStatusIcon.textContent = "+#{stats.added}"
      else if stats.deleted
        @gitStatusIcon.textContent = "-#{stats.deleted}"
      else
        @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else if repo.isStatusNew(status)
      @gitStatusIcon.classList.add('icon-diff-added', 'status-added')
      if @statusBar.getActiveBuffer()?
        @gitStatusIcon.textContent = "+#{@statusBar.getActiveBuffer().getLineCount()}"
      else
        @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else if repo.isPathIgnored(itemPath)
      @gitStatusIcon.classList.add('icon-diff-ignored',  'status-ignored')
      @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
