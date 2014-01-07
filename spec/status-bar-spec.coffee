{$$, fs, WorkspaceView} = require 'atom'
StatusBar = require '../lib/status-bar'
path = require 'path'
os = require 'os'

describe "StatusBar", ->
  [editor, statusBar, buffer] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    atom.workspaceView.simulateDomAttachment()
    StatusBar.activate()
    editor = atom.workspaceView.getActiveView()
    statusBar = atom.workspaceView.find('.status-bar').view()
    buffer = editor.getBuffer()

  describe "@initialize", ->
    it "appends only one status bar", ->
      expect(atom.workspaceView.find('.status-bar').length).toBe 1
      editor.splitRight()
      expect(atom.workspaceView.find('.status-bar').length).toBe 1

  describe ".initialize(editor)", ->
    it "displays the editor's buffer path, cursor buffer position, and buffer modified indicator", ->
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'sample.js'
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      expect(StatusBar.cursorPosition.text()).toBe '1,1'

    describe "when associated with an unsaved buffer", ->
      it "displays 'untitled' instead of the buffer's path, but still displays the buffer position", ->
        atom.workspaceView.openSync()
        StatusBar.activate()
        statusBar = atom.workspaceView.find('.status-bar').view()
        expect(StatusBar.fileInfo.currentPath.text()).toBe 'untitled'
        expect(StatusBar.cursorPosition.text()).toBe '1,1'

  describe "when the associated editor's path changes", ->
    it "updates the path in the status bar", ->
      atom.workspaceView.openSync('sample.txt')
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
      fs.writeFileSync(filePath, "")
      atom.workspaceView.openSync(filePath)
      editor = atom.workspaceView.getActiveView()
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
      atom.workspaceView.openSync('sample.txt')
      editor = atom.workspaceView.getActiveView()
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'

    it "doesn't update the buffer modified indicator for the old buffer", ->
      oldBuffer = editor.getBuffer()
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      atom.workspaceView.openSync('sample.txt')
      oldBuffer.setText("new text")
      advanceClock(buffer.stoppedChangingDelay)
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

  describe "when the associated editor's cursor position changes", ->
    it "updates the cursor position in the status bar", ->
      atom.workspaceView.attachToDom()
      editor.setCursorScreenPosition([1, 2])
      editor.updateDisplay()
      expect(StatusBar.cursorPosition.text()).toBe '2,3'

  describe "git branch label", ->
    beforeEach ->
      fs.removeSync(path.join(os.tmpdir(), '.git')) if fs.isDirectorySync(path.join(os.tmpdir(), '.git'))
      atom.workspaceView.attachToDom()

    it "displays the current branch for files in repositories", ->
      atom.project.setPath(atom.project.resolve('git/master.git'))
      atom.workspaceView.openSync('HEAD')
      expect(StatusBar.git.branchArea).toBeVisible()
      expect(StatusBar.git.branchLabel.text()).toBe 'master'

    it "doesn't display the current branch for a file not in a repository", ->
      atom.project.setPath(os.tmpdir())
      atom.workspaceView.openSync(path.join(os.tmpdir(), 'temp.txt'))
      expect(StatusBar.git.branchArea).toBeHidden()

    it "doesn't display the current branch for a file outside the current project", ->
      atom.workspaceView.openSync(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))
      expect(StatusBar.git.branchArea).toBeHidden()

  describe "git status label", ->
    [repo, filePath, originalPathText, newPath, ignorePath, ignoredPath, projectPath] = []

    beforeEach ->
      projectPath = atom.project.resolve('git/working-dir')
      fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
      atom.project.setPath(projectPath)
      filePath = atom.project.resolve('a.txt')
      newPath = atom.project.resolve('new.txt')
      fs.writeFileSync(newPath, "I'm new here")
      ignorePath = path.join(projectPath, '.gitignore')
      fs.writeFileSync(ignorePath, 'ignored.txt')
      ignoredPath = path.join(projectPath, 'ignored.txt')
      fs.writeFileSync(ignoredPath, '')
      atom.project.getRepo().getPathStatus(filePath)
      atom.project.getRepo().getPathStatus(newPath)
      originalPathText = fs.readFileSync(filePath, 'utf8')
      atom.workspaceView.attachToDom()

    afterEach ->
      fs.writeFileSync(filePath, originalPathText)
      fs.removeSync(newPath)
      fs.removeSync(ignorePath)
      fs.removeSync(ignoredPath)
      fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

    it "displays the modified icon for a changed file", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)
      atom.workspaceView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')

    it "doesn't display the modified icon for an unchanged file", ->
      atom.workspaceView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('')

    it "displays the new icon for a new file", ->
      atom.workspaceView.openSync(newPath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-added')

    it "displays the ignored icon for an ignored file", ->
      atom.workspaceView.openSync(ignoredPath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-ignored')

    it "updates when a status-changed event occurs", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)
      atom.workspaceView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')
      fs.writeFileSync(filePath, originalPathText)
      atom.project.getRepo().getPathStatus(filePath)
      expect(StatusBar.git.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)
      atom.workspaceView.openSync(filePath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "displays the diff stat for new files", ->
      atom.workspaceView.openSync(newPath)
      expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "does not display for files not in the current project", ->
      atom.workspaceView.openSync('/tmp/atom-specs/not-in-project.txt')
      expect(StatusBar.git.gitStatusIcon).toBeHidden()

  describe "when the active item view does not implement getCursorBufferPosition()", ->
    it "hides the cursor position view", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(StatusBar.cursorPosition).toBeHidden()

  describe "when the active item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      expect(StatusBar.fileInfo.currentPath).toBeVisible()

  describe "when the active item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath).toBeHidden()

  describe "when the active item's title changes", ->
    it "updates the path view with the new title", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editor.getPane().showItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      view.getTitle = => 'New Title'
      view.trigger 'title-changed'
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'New Title'
