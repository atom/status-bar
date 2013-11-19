{_, $, $$, View} = require 'atom'

module.exports =
class StatusBarView extends View
  @content: ->
    @div class: 'status-bar tool-panel panel-bottom', =>

      @div class: 'status-bar-right pull-right', =>
        @div class: 'git-branch inline-block', outlet: 'branchArea', =>
          @span class: 'icon icon-git-branch'
          @span class: 'branch-label', outlet: 'branchLabel'
        @div class: 'git-commits inline-block', outlet: 'commitsArea', =>
          @span class: 'icon icon-arrow-up commits-ahead-label', outlet: 'commitsAhead'
          @span class: 'icon icon-arrow-down commits-behind-label', outlet: 'commitsBehind'
        @div class: 'git-status inline-block', outlet: 'gitStatus', =>
          @span outlet: 'gitStatusIcon'

      @div class: 'status-bar-left', =>
        @div class: 'file-info inline-block', =>
          @span class: 'current-path', outlet: 'currentPath'
          @span class: 'buffer-modified', outlet: 'bufferModified'
        @div class: 'cursor-position inline-block', outlet: 'cursorPosition'
        @a href: '#', class: 'grammar-name inline-block', outlet: 'grammarName'

  initialize: ->
    @subscribe rootView, 'pane-container:active-pane-item-changed', =>
      @subscribeToBuffer()
      @updateStatusBar()
      @updatePathText()
    @subscribe rootView, 'pane:active-item-title-changed', =>
      @updatePathText()
      @updateBufferHasModifiedText()

    @subscribe rootView, 'cursor:moved', => @updateCursorPositionText()
    @subscribe @grammarName, 'click', => @getActiveView().trigger('grammar-selector:show'); false
    @subscribe rootView, 'editor:grammar-changed', => @updateGrammarText()
    @subscribe project, 'path-changed', => @subscribeToRepo()

    @subscribeToRepo()
    @subscribeToBuffer()

  attach: ->
    rootView.vertical.append(this) unless @hasParent()

  afterAttach: ->
    @commitsArea.hide()
    @updatePathText()
    @updateStatusBar()

  beforeRemove: ->
    @unsubscribeFromBuffer()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  getActiveItem: ->
    rootView.getActivePaneItem()

  getActiveView: ->
    rootView.getActiveView()

  unsubscribeFromBuffer: ->
    if @buffer?
      @buffer.off 'modified-status-changed', @updateBufferHasModifiedText
      @buffer.off 'saved', @updateStatusBar
      @buffer = null

  subscribeToRepo: ->
    @unsubscribe(@repo) if @repo?
    if repo = project.getRepo()
      @repo = repo
      @subscribe repo, 'status-changed', (path, status) =>
        @updateStatusBar() if path is @getActiveItemPath()
      @subscribe repo, 'statuses-changed', @updateStatusBar

  subscribeToBuffer: ->
    @unsubscribeFromBuffer()
    if @buffer = @getActiveItem()?.getBuffer?()
      @buffer.on 'modified-status-changed', @updateBufferHasModifiedText
      @buffer.on 'saved', @updateStatusBar

  updateStatusBar: =>
    @updateGrammarText()
    @updateBranchText()
    @updateBufferHasModifiedText(@buffer?.isModified())
    @updateStatusText()
    @updateCursorPositionText()

  updateGrammarText: ->
    grammar = @getActiveView()?.getGrammar?()
    if grammar?
      if grammar is atom.syntax.nullGrammar
        grammarName = 'Plain Text'
      else
        grammarName = grammar.name
      @grammarName.text(grammarName).show()
    else
      @grammarName.hide()

  updateBufferHasModifiedText: (isModified) =>
    if isModified
      @bufferModified.text('*') unless @isModified
      @isModified = true
    else
      @bufferModified.text('') if @isModified
      @isModified = false

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
      if @buffer?
        @gitStatusIcon.text("+#{@buffer.getLineCount()}")
      else
        @gitStatusIcon.text('')
    else if repo.isPathIgnored(itemPath)
      @gitStatusIcon.addClass('icon icon-diff-ignored status-ignored')
      @gitStatusIcon.text('')

    if @gitStatusIcon.attr('class') then @gitStatus.show() else @gitStatus.hide()

  updatePathText: ->
    if path = @getActiveItemPath()
      @currentPath.text(project.relativize(path)).show()
    else if title = @getActiveItem()?.getTitle?()
      @currentPath.text(title).show()
    else
      @currentPath.hide()

  updateCursorPositionText: ->
    if position = @getActiveView()?.getCursorBufferPosition?()
      @cursorPosition.text("#{position.row + 1},#{position.column + 1}").show()
    else
      @cursorPosition.hide()
