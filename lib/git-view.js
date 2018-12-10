const _ = require('underscore-plus')
const {CompositeDisposable} = require('atom')

module.exports =
class GitView {
  constructor () {
    this.element = document.createElement('status-bar-git')
    this.element.classList.add('git-view')

    this.createBranchArea()
    this.createCommitsArea()
    this.createStatusArea()

    this.activeItemSubscription = atom.workspace.getCenter().onDidChangeActivePaneItem(() => this.subscribeToActiveItem())
    this.projectPathSubscription = atom.project.onDidChangePaths(() => this.subscribeToRepositories())
    this.subscribeToRepositories()
    this.subscribeToActiveItem()
  }

  createBranchArea () {
    this.branchArea = document.createElement('div')
    this.branchArea.classList.add('git-branch', 'inline-block')
    this.element.appendChild(this.branchArea)
    this.element.branchArea = this.branchArea

    const branchIcon = document.createElement('span')
    branchIcon.classList.add('icon', 'icon-git-branch')
    this.branchArea.appendChild(branchIcon)

    this.branchLabel = document.createElement('span')
    this.branchLabel.classList.add('branch-label')
    this.branchArea.appendChild(this.branchLabel)
    this.element.branchLabel = this.branchLabel
  }

  createCommitsArea () {
    this.commitsArea = document.createElement('div')
    this.commitsArea.classList.add('git-commits', 'inline-block')
    this.element.appendChild(this.commitsArea)

    this.commitsAhead = document.createElement('span')
    this.commitsAhead.classList.add('icon', 'icon-arrow-up', 'commits-ahead-label')
    this.commitsArea.appendChild(this.commitsAhead)

    this.commitsBehind = document.createElement('span')
    this.commitsBehind.classList.add('icon', 'icon-arrow-down', 'commits-behind-label')
    this.commitsArea.appendChild(this.commitsBehind)
  }

  createStatusArea () {
    this.gitStatus = document.createElement('div')
    this.gitStatus.classList.add('git-status', 'inline-block')
    this.element.appendChild(this.gitStatus)

    this.gitStatusIcon = document.createElement('span')
    this.gitStatusIcon.classList.add('icon')
    this.gitStatus.appendChild(this.gitStatusIcon)
    this.element.gitStatusIcon = this.gitStatusIcon
  }

  subscribeToActiveItem () {
    const activeItem = this.getActiveItem()

    if (this.savedSubscription) this.savedSubscription.dispose()
    this.savedSubscription = activeItem && typeof activeItem.onDidSave === 'function' && activeItem.onDidSave(() => this.update())

    this.update()
  }

  subscribeToRepositories () {
    if (this.repositorySubscriptions) this.repositorySubscriptions.dispose()
    this.repositorySubscriptions = new CompositeDisposable()

    for (let repo of atom.project.getRepositories()) {
      if (repo) {
        this.repositorySubscriptions.add(repo.onDidChangeStatus(({path, status}) => {
          if (path === this.getActiveItemPath()) this.update()
        }))
        this.repositorySubscriptions.add(repo.onDidChangeStatuses(() => this.update()))
      }
    }
  }

  destroy () {
    if (this.activeItemSubscription) this.activeItemSubscription.dispose()
    if (this.projectPathSubscription) this.projectPathSubscription.dispose()
    if (this.savedSubscription) this.savedSubscription.dispose()
    if (this.repositorySubscriptions) this.repositorySubscriptions.dispose()
    if (this.branchTooltipDisposable) this.branchTooltipDisposable.dispose()
    if (this.commitsAheadTooltipDisposable) this.commitsAheadTooltipDisposable.dispose()
    if (this.commitsBehindTooltipDisposable) this.commitsBehindTooltipDisposable.dispose()
    if (this.statusTooltipDisposable) this.statusTooltipDisposable.dispose()
  }

  getActiveItemPath () {
    const activeItem = this.getActiveItem()
    return activeItem && typeof activeItem.getPath === 'function' && activeItem.getPath()
  }

  getRepositoryForActiveItem () {
    const [rootDir] = atom.project.relativizePath(this.getActiveItemPath())
    const rootDirIndex = atom.project.getPaths().indexOf(rootDir)
    if (rootDirIndex >= 0) {
      return atom.project.getRepositories()[rootDirIndex]
    } else {
      for (let repo of atom.project.getRepositories()) {
        if (repo) return repo
      }
    }
  }

  getActiveItem () {
    return atom.workspace.getCenter().getActivePaneItem()
  }

  update () {
    const repo = this.getRepositoryForActiveItem()
    this.updateBranchText(repo)
    this.updateAheadBehindCount(repo)
    this.updateStatusText(repo)
  }

  updateBranchText (repo) {
    if (this.showGitInformation(repo)) {
      const head = repo.getShortHead(this.getActiveItemPath())
      this.branchLabel.textContent = head
      if (head) this.branchArea.style.display = ''
      if (this.branchTooltipDisposable) {
        this.branchTooltipDisposable.dispose()
      }
      this.branchTooltipDisposable = atom.tooltips.add(this.branchArea, {title: `On branch ${head}`})
    } else {
      this.branchArea.style.display = 'none'
    }
  }

  showGitInformation (repo) {
    if (repo == null) return false

    const itemPath = this.getActiveItemPath()
    if (itemPath) {
      return atom.project.contains(itemPath)
    } else {
      return this.getActiveItem() == null
    }
  }

  updateAheadBehindCount (repo) {
    if (!this.showGitInformation(repo)) {
      this.commitsArea.style.display = 'none'
      return
    }

    const itemPath = this.getActiveItemPath()
    const {ahead, behind} = repo.getCachedUpstreamAheadBehindCount(itemPath)
    if (ahead > 0) {
      this.commitsAhead.textContent = ahead
      this.commitsAhead.style.display = ''
      if (this.commitsAheadTooltipDisposable) this.commitsAheadTooltipDisposable.dispose()
      this.commitsAheadTooltipDisposable = atom.tooltips.add(this.commitsAhead, {title: `${_.pluralize(ahead, 'commit')} ahead of upstream`})
    } else {
      this.commitsAhead.style.display = 'none'
    }

    if (behind > 0) {
      this.commitsBehind.textContent = behind
      this.commitsBehind.style.display = ''
      if (this.commitsBehindTooltipDisposable) this.commitsBehindTooltipDisposable.dispose()
      this.commitsBehindTooltipDisposable = atom.tooltips.add(this.commitsBehind, {title: `${_.pluralize(behind, 'commit')} behind upstream`})
    } else {
      this.commitsBehind.style.display = 'none'
    }

    if (ahead > 0 || behind > 0) {
      this.commitsArea.style.display = ''
    } else {
      this.commitsArea.style.display = 'none'
    }
  }

  clearStatus () {
    this.gitStatusIcon.classList.remove('icon-diff-modified', 'status-modified', 'icon-diff-added', 'status-added', 'icon-diff-ignored', 'status-ignored')
  }

  updateAsNewFile () {
    this.clearStatus()

    this.gitStatusIcon.classList.add('icon-diff-added', 'status-added')
    const textEditor = atom.workspace.getActiveTextEditor()
    if (textEditor) {
      this.gitStatusIcon.textContent = `+${textEditor.getLineCount()}`
      this.updateTooltipText(`${_.pluralize(textEditor.getLineCount(), 'line')} in this new file not yet committed`)
    } else {
      this.gitStatusIcon.textContent = ''
      this.updateTooltipText()
    }

    this.gitStatus.style.display = ''
  }

  updateAsModifiedFile (repo, path) {
    const stats = repo.getDiffStats(path)
    this.clearStatus()

    this.gitStatusIcon.classList.add('icon-diff-modified', 'status-modified')
    if (stats.added && stats.deleted) {
      this.gitStatusIcon.textContent = `+${stats.added}, -${stats.deleted}`
      this.updateTooltipText(`${_.pluralize(stats.added, 'line')} added and ${_.pluralize(stats.deleted, 'line')} deleted in this file not yet committed`)
    } else if (stats.added) {
      this.gitStatusIcon.textContent = `+${stats.added}`
      this.updateTooltipText(`${_.pluralize(stats.added, 'line')} added to this file not yet committed`)
    } else if (stats.deleted) {
      this.gitStatusIcon.textContent = `-${stats.deleted}`
      this.updateTooltipText(`${_.pluralize(stats.deleted, 'line')} deleted from this file not yet committed`)
    } else {
      this.gitStatusIcon.textContent = ''
      this.updateTooltipText()
    }

    this.gitStatus.style.display = ''
  }

  updateAsIgnoredFile () {
    this.clearStatus()

    this.gitStatusIcon.classList.add('icon-diff-ignored', 'status-ignored')
    this.gitStatusIcon.textContent = ''
    this.gitStatus.style.display = ''
    this.updateTooltipText('File is ignored by git')
  }

  updateTooltipText (text) {
    if (this.statusTooltipDisposable) this.statusTooltipDisposable.dispose()
    if (text) this.statusTooltipDisposable = atom.tooltips.add(this.gitStatusIcon, {title: text})
  }

  updateStatusText (repo) {
    const hideStatus = () => {
      this.clearStatus()
      this.gitStatus.style.display = 'none'
    }

    const itemPath = this.getActiveItemPath()
    if (this.showGitInformation(repo) && itemPath) {
      const status = repo.getCachedPathStatus(itemPath) || 0
      if (repo.isStatusNew(status)) {
        this.updateAsNewFile()
      } else if (repo.isStatusModified(status)) {
        this.updateAsModifiedFile(repo, itemPath)
      } else if (repo.isPathIgnored(itemPath)) {
        this.updateAsIgnoredFile()
      } else {
        hideStatus()
      }
    } else {
      hideStatus()
    }
  }
}
