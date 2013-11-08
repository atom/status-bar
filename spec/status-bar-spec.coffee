{_, $, $$, fs, RootView} = require 'atom'
StatusBar = require '../lib/status-bar-view'
path = require 'path'
os = require 'os'

describe "StatusBar", ->
  [editor, statusBar, buffer] = []

  beforeEach ->
    window.rootView = new RootView
    rootView.openSync('sample.js')
    rootView.simulateDomAttachment()
    StatusBar.activate()
    editor = rootView.getActiveView()
    statusBar = rootView.find('.status-bar').view()
    buffer = editor.getBuffer()

  describe "@initialize", ->
    it "appends a status bar to all existing and new editors", ->
      expect(rootView.panes.find('.pane').length).toBe 1
      expect(rootView.panes.find('.pane > .status-bar').length).toBe 1
      editor.splitRight()
      expect(rootView.find('.pane').length).toBe 2
      expect(rootView.panes.find('.pane > .status-bar').length).toBe 2

  describe ".initialize(editor)", ->
    it "displays the editor's buffer path, cursor buffer position, and buffer modified indicator", ->
      expect(statusBar.currentPath.text()).toBe 'sample.js'
      expect(statusBar.bufferModified.text()).toBe ''
      expect(statusBar.cursorPosition.text()).toBe '1,1'

    describe "when associated with an unsaved buffer", ->
      it "displays 'untitled' instead of the buffer's path, but still displays the buffer position", ->
        rootView.remove()
        window.rootView = new RootView
        rootView.openSync()
        rootView.simulateDomAttachment()
        StatusBar.activate()
        statusBar = rootView.find('.status-bar').view()
        expect(statusBar.currentPath.text()).toBe 'untitled'
        expect(statusBar.cursorPosition.text()).toBe '1,1'

  describe "when the associated editor's path changes", ->
    it "updates the path in the status bar", ->
      rootView.openSync('sample.txt')
      expect(statusBar.currentPath.text()).toBe 'sample.txt'

  describe "when the associated editor's buffer's content changes", ->
    it "enables the buffer modified indicator", ->
      expect(statusBar.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe '*'
      editor.backspace()

  describe "when the buffer content has changed from the content on disk", ->
    it "disables the buffer modified indicator on save", ->
      filePath = path.join(os.tmpdir(), "atom-whitespace.txt")
      fs.writeSync(filePath, "")
      rootView.openSync(filePath)
      editor = rootView.getActiveView()
      expect(statusBar.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe '*'
      editor.getBuffer().save()
      expect(statusBar.bufferModified.text()).toBe ''

    it "disables the buffer modified indicator if the content matches again", ->
      expect(statusBar.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe '*'
      editor.backspace()
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe ''

    it "disables the buffer modified indicator when the change is undone", ->
      expect(statusBar.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe '*'
      editor.undo()
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe ''

  describe "when the buffer changes", ->
    it "updates the buffer modified indicator for the new buffer", ->
      expect(statusBar.bufferModified.text()).toBe ''
      rootView.openSync('sample.txt')
      editor = rootView.getActiveView()
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe '*'

    it "doesn't update the buffer modified indicator for the old buffer", ->
      oldBuffer = editor.getBuffer()
      expect(statusBar.bufferModified.text()).toBe ''
      rootView.openSync('sample.txt')
      oldBuffer.setText("new text")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.bufferModified.text()).toBe ''

  describe "when the associated editor's cursor position changes", ->
    it "updates the cursor position in the status bar", ->
      rootView.attachToDom()
      editor.setCursorScreenPosition([1, 2])
      editor.updateDisplay()
      expect(statusBar.cursorPosition.text()).toBe '2,3'

  describe "git branch label", ->
    beforeEach ->
      fs.remove(path.join(os.tmpdir(), '.git')) if fs.isDirectorySync(path.join(os.tmpdir(), '.git'))
      rootView.attachToDom()

    it "displays the current branch for files in repositories", ->
      project.setPath(project.resolve('git/master.git'))
      rootView.openSync('HEAD')
      expect(statusBar.branchArea).toBeVisible()
      expect(statusBar.branchLabel.text()).toBe 'master'

    it "doesn't display the current branch for a file not in a repository", ->
      project.setPath(os.tmpdir())
      rootView.openSync(path.join(os.tmpdir(), 'temp.txt'))
      expect(statusBar.branchArea).toBeHidden()

    it "doesn't display the current branch for a file outside the current project", ->
      rootView.openSync(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))
      expect(statusBar.branchArea).toBeHidden()

  describe "git status label", ->
    [repo, filePath, originalPathText, newPath, ignorePath, ignoredPath, projectPath] = []

    beforeEach ->
      projectPath = project.resolve('git/working-dir')
      fs.move(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
      project.setPath(projectPath)
      filePath = project.resolve('a.txt')
      newPath = project.resolve('new.txt')
      fs.writeSync(newPath, "I'm new here")
      ignorePath = path.join(projectPath, '.gitignore')
      fs.writeSync(ignorePath, 'ignored.txt')
      ignoredPath = path.join(projectPath, 'ignored.txt')
      fs.writeSync(ignoredPath, '')
      project.getRepo().getPathStatus(filePath)
      project.getRepo().getPathStatus(newPath)
      originalPathText = fs.read(filePath)
      rootView.attachToDom()

    afterEach ->
      fs.writeSync(filePath, originalPathText)
      fs.remove(newPath)
      fs.remove(ignorePath)
      fs.remove(ignoredPath)
      fs.move(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

    it "displays the modified icon for a changed file", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      rootView.openSync(filePath)
      expect(statusBar.gitStatusIcon).toHaveClass('icon-diff-modified')

    it "doesn't display the modified icon for an unchanged file", ->
      rootView.openSync(filePath)
      expect(statusBar.gitStatusIcon).toHaveText('')

    it "displays the new icon for a new file", ->
      rootView.openSync(newPath)
      expect(statusBar.gitStatusIcon).toHaveClass('icon-diff-added')

    it "displays the ignored icon for an ignored file", ->
      rootView.openSync(ignoredPath)
      expect(statusBar.gitStatusIcon).toHaveClass('icon-diff-ignored')

    it "updates when a status-changed event occurs", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      rootView.openSync(filePath)
      expect(statusBar.gitStatusIcon).toHaveClass('icon-diff-modified')
      fs.writeSync(filePath, originalPathText)
      project.getRepo().getPathStatus(filePath)
      expect(statusBar.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      rootView.openSync(filePath)
      expect(statusBar.gitStatusIcon).toHaveText('+1')

    it "displays the diff stat for new files", ->
      rootView.openSync(newPath)
      expect(statusBar.gitStatusIcon).toHaveText('+1')

    it "does not display for files not in the current project", ->
      rootView.openSync('/tmp/atom-specs/not-in-project.txt')
      expect(statusBar.gitStatusIcon).toBeHidden()

  describe "grammar label", ->
    beforeEach ->
      atom.activatePackage('language-text', sync: true)
      atom.activatePackage('language-javascript', sync: true)

    it "displays the name of the current grammar", ->
      expect(statusBar.find('.grammar-name').text()).toBe 'JavaScript'

    it "displays Plain Text when the current grammar is the null grammar", ->
      rootView.attachToDom()
      editor.activeEditSession.setGrammar(syntax.nullGrammar)
      expect(statusBar.find('.grammar-name')).toBeVisible()
      expect(statusBar.find('.grammar-name').text()).toBe 'Plain Text'
      editor.reloadGrammar()
      expect(statusBar.find('.grammar-name')).toBeVisible()
      expect(statusBar.find('.grammar-name').text()).toBe 'JavaScript'

    it "hides the label when the current grammar is null", ->
      rootView.attachToDom()
      spyOn(editor, 'getGrammar').andReturn null
      editor.activeEditSession.setGrammar(syntax.nullGrammar)

      expect(statusBar.find('.grammar-name')).toBeHidden()

    describe "when the editor's grammar changes", ->
      it "displays the new grammar of the editor", ->
        syntax.setGrammarOverrideForPath(editor.getPath(), 'text.plain')
        editor.reloadGrammar()
        expect(statusBar.find('.grammar-name').text()).toBe 'Plain Text'

    describe "when clicked", ->
      it "toggles the grammar-selector:show event", ->
        eventHandler = jasmine.createSpy('eventHandler')
        editor.on 'grammar-selector:show', eventHandler
        statusBar.find('.grammar-name').click()
        expect(eventHandler).toHaveBeenCalled()

  describe "when the active item view does not implement getCursorBufferPosition()", ->
    it "hides the cursor position view", ->
      rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(statusBar.cursorPosition).toBeHidden()

  describe "when the active item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(statusBar.currentPath.text()).toBe 'View Title'
      expect(statusBar.currentPath).toBeVisible()

  describe "when the active item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(statusBar.currentPath).toBeHidden()

  describe "when the active item's title changes", ->
    it "updates the path view with the new title", ->
      rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(statusBar.currentPath.text()).toBe 'View Title'
      view.getTitle = => 'New Title'
      view.trigger 'title-changed'
      expect(statusBar.currentPath.text()).toBe 'New Title'
