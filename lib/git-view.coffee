class GitView extends HTMLElement
  initialize: ->
    @classList.add('git-view')

    @createBranchArea()
    @createCommitsArea()
    @createStatusArea()

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @projectPathSubscription = atom.project.onDidChangePaths =>
      @subscribeToRepo()
    @subscribeToRepo()
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

  subscribeToRepo: ->
    @statusChangedSubscription?.dispose()
    @statusesChangedSubscription?.dispose()

    if repo = atom.project.getRepositories()[0]
      @statusChangedSubscription = repo.onDidChangeStatus ({path, status}) =>
        @update() if path is @getActiveItemPath()
      @statusesChangedSubscription = repo.onDidChangeStatuses =>
        @update()

  destroy: ->
    @activeItemSubscription?.dispose()
    @projectPathSubscription?.dispose()

    @savedSubscription?.dispose()
    @statusChangedSubscription?.dispose()
    @statusesChangedSubscription?.dispose()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  update: ->
    @updateBranchText()
    @updateAheadBehindCount()
    @updateStatusText()

  updateBranchText: ->
    @branchArea.style.display = 'none'
    if @showBranchInformation()
      head = atom.project.getRepositories()[0]?.getShortHead(@getActiveItemPath()) or ''
      @branchLabel.textContent = head
      @branchArea.style.display = '' if head

  showBranchInformation: ->
    if itemPath = @getActiveItemPath()
      atom.project.contains(itemPath)
    else
      not @getActiveItem()?

  updateAheadBehindCount: ->
    itemPath = @getActiveItemPath()
    repo = atom.project.getRepositories()[0]

    if repo? and @showBranchInformation()
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

    if ahead > 0 or behind > 0
      @commitsArea.style.display = ''
    else
      @commitsArea.style.display = 'none'

  updateStatusText: ->
    itemPath = @getActiveItemPath()
    repo = atom.project.getRepositories()[0]

    status = repo?.getCachedPathStatus(itemPath) ? 0
    @gitStatusIcon.classList.remove('icon-diff-modified', 'status-modified', 'icon-diff-added', 'status-added', 'icon-diff-ignored', 'status-ignored')

    if repo?.isStatusModified(status)
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
    else if repo?.isStatusNew(status)
      @gitStatusIcon.classList.add('icon-diff-added', 'status-added')
      if textEditor = atom.workspace.getActiveTextEditor()
        @gitStatusIcon.textContent = "+#{textEditor.getLineCount()}"
      else
        @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else if repo?.isPathIgnored(itemPath)
      @gitStatusIcon.classList.add('icon-diff-ignored',  'status-ignored')
      @gitStatusIcon.textContent = ''
      @gitStatus.style.display = ''
    else
      @gitStatus.style.display = 'none'

module.exports = document.registerElement('status-bar-git', prototype: GitView.prototype, extends: 'div')
