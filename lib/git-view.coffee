{View} = require 'atom'

module.exports =
class GitView extends View
  @content: ->
    @div class: 'git-view', =>
      @div class: 'git-branch inline-block', outlet: 'branchArea', =>
        @span class: 'icon icon-git-branch'
        @span class: 'branch-label', outlet: 'branchLabel'
      @div class: 'git-commits inline-block', outlet: 'commitsArea', =>
        @span class: 'icon icon-arrow-up commits-ahead-label', outlet: 'commitsAhead'
        @span class: 'icon icon-arrow-down commits-behind-label', outlet: 'commitsBehind'
      @div class: 'git-status inline-block', outlet: 'gitStatus', =>
        @span outlet: 'gitStatusIcon'

  initialize: (@statusBar) ->
    @subscribeToBuffer 'saved', @update
    @subscribe atom.rootView, 'pane-container:active-pane-item-changed', @update
    @subscribe project, 'path-changed', @subscribeToRepo

    @subscribeToRepo()

  afterAttach: ->
    @update()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  getActiveItem: ->
    atom.rootView.getActivePaneItem()

  getActiveView: ->
    atom.rootView.getActiveView()

  subscribeToRepo: =>
    @unsubscribe(@repo) if @repo?
    if repo = project.getRepo()
      @repo = repo
      @subscribe repo, 'status-changed', (path, status) =>
        @update() if path is @getActiveItemPath()
      @subscribe repo, 'statuses-changed', @update

  update: =>
    @updateBranchText()
    @updateStatusText()

  updateBranchText: ->
    @branchArea.hide()
    return unless project.contains(@getActiveItemPath())

    head = project.getRepo()?.getShortHead() or ''
    @branchLabel.text(head)
    @branchArea.show() if head

  updateStatusText: ->
    itemPath = @getActiveItemPath()
    @gitStatus.hide()
    @commitsArea.hide()
    return unless project.contains(itemPath)

    repo = project.getRepo()
    return unless repo?

    if repo.upstream.ahead > 0
      @commitsAhead.text(repo.upstream.ahead).show()
    else
      @commitsAhead.hide()

    if repo.upstream.behind > 0
      @commitsBehind.text(repo.upstream.behind).show()
    else
      @commitsBehind.hide()

    @commitsArea.show() if repo.upstream.ahead > 0 or repo.upstream.behind > 0

    status = repo.statuses[itemPath]
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
