{CompositeDisposable} = require "atom"

class GitView extends HTMLElement
  initialize: ->
    @classList.add('git-view')

    @createBranchArea()
    @createCommitsArea()
    @createStatusArea()

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @projectPathSubscription = atom.project.onDidChangePaths =>
      @subscribeToRepositories()
    @subscribeToRepositories()
    @subscribeToActiveItem()

  createBranchArea: ->
    @branchArea = document.createElement('div')
    @branchArea.classList.add('git-branch', 'inline-block')
    @appendChild(@branchArea)

    branchIcon = document.createElement('span')
    branchIcon.classList.add('icon', 'icon-git-branch')
    @branchArea.appendChild(branchIcon)

    @branchLabel = document.createElement('span')
    @branchLabel.classList.add('branch-label')
    @branchArea.appendChild(@branchLabel)

  createCommitsArea: ->
    @commitsArea = document.createElement('div')
    @commitsArea.classList.add('git-commits', 'inline-block')
    @appendChild(@commitsArea)

    @commitsAhead = document.createElement('span')
    @commitsAhead.classList.add('icon', 'icon-arrow-up', 'commits-ahead-label')
    @commitsArea.appendChild(@commitsAhead)

    @commitsBehind = document.createElement('span')
    @commitsBehind.classList.add('icon', 'icon-arrow-down', 'commits-behind-label')
    @commitsArea.appendChild(@commitsBehind)

  createStatusArea: ->
    @gitStatus = document.createElement('div')
    @gitStatus.classList.add('git-status', 'inline-block')
    @appendChild(@gitStatus)

    @gitStatusIcon = document.createElement('span')
    @gitStatusIcon.classList.add('icon')
    @gitStatus.appendChild(@gitStatusIcon)

  subscribeToActiveItem: ->
    activeItem = @getActiveItem()

    @savedSubscription?.dispose()
    @savedSubscription = activeItem?.onDidSave? => @update()

    @update()

  subscribeToRepositories: ->
    @repositorySubscriptions?.dispose()
    @repositorySubscriptions = new CompositeDisposable

    for repo in atom.project.getRepositories() when repo?
      @repositorySubscriptions.add repo.onDidChangeStatus ({path, status}) =>
        @update() if path is @getActiveItemPath()
      @repositorySubscriptions.add repo.onDidChangeStatuses =>
        @update()

  destroy: ->
    @activeItemSubscription?.dispose()
    @projectPathSubscription?.dispose()
    @savedSubscription?.dispose()
    @repositorySubscriptions?.dispose()
    @branchTooltipDisposable?.dispose()
    @commitsAheadTooltipDisposable?.dispose()
    @commitsBehindTooltipDisposable?.dispose()
    @statusTooltipDisposable?.dispose()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  getRepositoryForActiveItem: ->
    [rootDir] = atom.project.relativizePath(@getActiveItemPath())
    rootDirIndex = atom.project.getPaths().indexOf(rootDir)
    if rootDirIndex >= 0
      atom.project.getRepositories()[rootDirIndex]
    else
      for repo in atom.project.getRepositories() when repo
        return repo

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  update: ->
    repo = @getRepositoryForActiveItem()
    @updateBranchText(repo)
    @updateAheadBehindCount(repo)
    @updateStatusText(repo)

  updateBranchText: (repo) ->
    @branchArea.style.display = 'none'
    if @showBranchInformation()
      head = repo?.getShortHead(@getActiveItemPath()) or ''
      @branchLabel.textContent = head
      @branchArea.style.display = '' if head
      @branchTooltipDisposable?.dispose()
      @branchTooltipDisposable = atom.tooltips.add @branchArea, title: "On branch #{head}"

  showBranchInformation: ->
    if itemPath = @getActiveItemPath()
      atom.project.contains(itemPath)
    else
      not @getActiveItem()?

  updateAheadBehindCount: (repo) ->
    itemPath = @getActiveItemPath()

    if repo? and @showBranchInformation()
      {ahead, behind} = repo.getCachedUpstreamAheadBehindCount(itemPath) ? {}

      if ahead > 0
        @commitsAhead.textContent = ahead
        @commitsAhead.style.display = ''
        @commitsAheadTooltipDisposable?.dispose()
        @commitsAheadTooltipDisposable = atom.tooltips.add @commitsAhead, title: "#{ahead} commits ahead of upstream"
      else
        @commitsAhead.style.display = 'none'

      if behind > 0
        @commitsBehind.textContent = behind
        @commitsBehind.style.display = ''
        @commitsBehindTooltipDisposable?.dispose()
        @commitsBehindTooltipDisposable = atom.tooltips.add @commitsBehind, title: "#{behind} commits behind upstream"
      else
        @commitsBehind.style.display = 'none'

    if ahead > 0 or behind > 0
      @commitsArea.style.display = ''
    else
      @commitsArea.style.display = 'none'

  updateStatusText: (repo) ->
    itemPath = @getActiveItemPath()

    status = repo?.getCachedPathStatus(itemPath) ? 0
    @gitStatusIcon.classList.remove('icon-diff-modified', 'status-modified', 'icon-diff-added', 'status-added', 'icon-diff-ignored', 'status-ignored')

    tooltipText = null;

    if repo?.isStatusModified(status)
      @gitStatusIcon.classList.add('icon-diff-modified', 'status-modified')
      stats = repo.getDiffStats(itemPath)
      if stats.added and stats.deleted
        @gitStatusIcon.textContent = "+#{stats.added}, -#{stats.deleted}"
        tooltipText = "#{stats.added} lines added and -#{stats.deleted} lines deleted in this file not yet committed"
      else if stats.added
        @gitStatusIcon.textContent = "+#{stats.added}"
        tooltipText = "#{stats.added} lines added to this file not yet committed"
      else if stats.deleted
        @gitStatusIcon.textContent = "-#{stats.deleted}"
        tooltipText = "#{stats.added} lines added from this file not yet committed"
      else
        @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else if repo?.isStatusNew(status)
      @gitStatusIcon.classList.add('icon-diff-added', 'status-added')
      if textEditor = atom.workspace.getActiveTextEditor()
        @gitStatusIcon.textContent = "+#{textEditor.getLineCount()}"
        tooltipText = "#{textEditor.getLineCount()} lines in this new file not yet committed"
      else
        @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else if repo?.isPathIgnored(itemPath)
      @gitStatusIcon.classList.add('icon-diff-ignored',  'status-ignored')
      tooltipText = "File is ignored by git"
      @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else
      @gitStatus.style.display = 'none'

    @statusTooltipDisposable?.dispose()
    if tooltipText
      @statusTooltipDisposable = atom.tooltips.add @gitStatusIcon, title: tooltipText

module.exports = document.registerElement('status-bar-git', prototype: GitView.prototype, extends: 'div')
