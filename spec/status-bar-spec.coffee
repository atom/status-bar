{_, $, $$, fs, RootView} = require 'atom'
StatusBar = require '../lib/status-bar'
path = require 'path'
os = require 'os'

describe "StatusBar", ->
  [editor, statusBar, buffer] = []

  beforeEach ->
    atom.rootView = new RootView
    atom.rootView.openSync('sample.js')
    atom.rootView.simulateDomAttachment()
    StatusBar.activate()
    editor = atom.rootView.getActiveView()
    statusBar = atom.rootView.find('.status-bar').view()
    buffer = editor.getBuffer()

  describe "@initialize", ->
    it "appends only one status bar", ->
      expect(atom.rootView.vertical.find('.status-bar').length).toBe 1
      editor.splitRight()
      expect(atom.rootView.vertical.find('.status-bar').length).toBe 1

  describe ".initialize(editor)", ->
    it "displays the editor's buffer path, cursor buffer position, and buffer modified indicator", ->
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'sample.js'
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      expect(StatusBar.cursorPosition.text()).toBe '1,1'

    describe "when associated with an unsaved buffer", ->
      it "displays 'untitled' instead of the buffer's path, but still displays the buffer position", ->
        atom.rootView.remove()
        atom.rootView = new RootView
        atom.rootView.openSync()
        atom.rootView.simulateDomAttachment()
        StatusBar.activate()
        statusBar = atom.rootView.find('.status-bar').view()
        expect(StatusBar.fileInfo.currentPath.text()).toBe 'untitled'
        expect(StatusBar.cursorPosition.text()).toBe '1,1'

  describe "when the associated editor's path changes", ->
    it "updates the path in the status bar", ->
      atom.rootView.openSync('sample.txt')
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'sample.txt'

  describe "when the associated editor's buffer's content changes", ->
    it "enables the buffer modified indicator", ->
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'
      editor.backspace()

  describe "when the buffer content has changed from the content on disk", ->
    it "disables the buffer modified indicator on save", ->
      filePath = path.join(os.tmpdir(), "atom-whitespace.txt")
      fs.writeSync(filePath, "")
      atom.rootView.openSync(filePath)
      editor = atom.rootView.getActiveView()
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'
      editor.getBuffer().save()
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

    it "disables the buffer modified indicator if the content matches again", ->
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'
      editor.backspace()
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

    it "disables the buffer modified indicator when the change is undone", ->
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'
      editor.undo()
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

  describe "when the buffer changes", ->
    it "updates the buffer modified indicator for the new buffer", ->
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      atom.rootView.openSync('sample.txt')
      editor = atom.rootView.getActiveView()
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'

    it "doesn't update the buffer modified indicator for the old buffer", ->
      oldBuffer = editor.getBuffer()
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      atom.rootView.openSync('sample.txt')
      oldBuffer.setText("new text")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

  describe "when the associated editor's cursor position changes", ->
    it "updates the cursor position in the status bar", ->
      atom.rootView.attachToDom()
      editor.setCursorScreenPosition([1, 2])
      editor.updateDisplay()
      expect(StatusBar.cursorPosition.text()).toBe '2,3'

  describe "git branch label", ->
    beforeEach ->
      fs.remove(path.join(os.tmpdir(), '.git')) if fs.isDirectorySync(path.join(os.tmpdir(), '.git'))
      atom.rootView.attachToDom()

    it "displays the current branch for files in repositories", ->
      project.setPath(project.resolve('git/master.git'))
      atom.rootView.openSync('HEAD')
      expect(StatusBar.git.branchArea).toBeVisible()
      expect(StatusBar.git.branchLabel.text()).toBe 'master'

    it "doesn't display the current branch for a file not in a repository", ->
      project.setPath(os.tmpdir())
      atom.rootView.openSync(path.join(os.tmpdir(), 'temp.txt'))
      expect(StatusBar.git.branchArea).toBeHidden()

    it "doesn't display the current branch for a file outside the current project", ->
      atom.rootView.openSync(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))
      expect(StatusBar.git.branchArea).toBeHidden()

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
      atom.rootView.attachToDom()

    afterEach ->
      fs.writeSync(filePath, originalPathText)
      fs.remove(newPath)
      fs.remove(ignorePath)
      fs.remove(ignoredPath)
      fs.move(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

    it "displays the modified icon for a changed file", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      atom.rootView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')

    it "doesn't display the modified icon for an unchanged file", ->
      atom.rootView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('')

    it "displays the new icon for a new file", ->
      atom.rootView.openSync(newPath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-added')

    it "displays the ignored icon for an ignored file", ->
      atom.rootView.openSync(ignoredPath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-ignored')

    it "updates when a status-changed event occurs", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      atom.rootView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')
      fs.writeSync(filePath, originalPathText)
      project.getRepo().getPathStatus(filePath)
      expect(StatusBar.git.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeSync(filePath, "i've changed for the worse")
      project.getRepo().getPathStatus(filePath)
      atom.rootView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "displays the diff stat for new files", ->
      atom.rootView.openSync(newPath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "does not display for files not in the current project", ->
      atom.rootView.openSync('/tmp/atom-specs/not-in-project.txt')
      expect(StatusBar.git.gitStatusIcon).toBeHidden()

  describe "grammar label", ->
    beforeEach ->
      atom.activatePackage('language-text', sync: true)
      atom.activatePackage('language-javascript', sync: true)

    it "displays the name of the current grammar", ->
      expect(statusBar.find('.grammar-name').text()).toBe 'JavaScript'

    it "displays Plain Text when the current grammar is the null grammar", ->
      atom.rootView.attachToDom()
      editor.activeEditSession.setGrammar(atom.syntax.nullGrammar)
      expect(statusBar.find('.grammar-name')).toBeVisible()
      expect(statusBar.find('.grammar-name').text()).toBe 'Plain Text'
      editor.reloadGrammar()
      expect(statusBar.find('.grammar-name')).toBeVisible()
      expect(statusBar.find('.grammar-name').text()).toBe 'JavaScript'

    it "hides the label when the current grammar is null", ->
      atom.rootView.attachToDom()
      spyOn(editor, 'getGrammar').andReturn null
      editor.activeEditSession.setGrammar(atom.syntax.nullGrammar)

      expect(statusBar.find('.grammar-name')).toBeHidden()

    describe "when the editor's grammar changes", ->
      it "displays the new grammar of the editor", ->
        atom.syntax.setGrammarOverrideForPath(editor.getPath(), 'text.plain')
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
      atom.rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(StatusBar.cursorPosition).toBeHidden()

  describe "when the active item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      atom.rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      expect(StatusBar.fileInfo.currentPath).toBeVisible()

  describe "when the active item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      atom.rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath).toBeHidden()

  describe "when the active item's title changes", ->
    it "updates the path view with the new title", ->
      atom.rootView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      view.getTitle = => 'New Title'
      view.trigger 'title-changed'
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'New Title'
