{$$, WorkspaceView} = require 'atom'
fs = require 'fs-plus'
StatusBar = require '../lib/status-bar'
path = require 'path'
os = require 'os'

describe "StatusBar", ->
  [editor, editorView, statusBar, buffer] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      atom.workspaceView.simulateDomAttachment()
      StatusBar.activate()
      editorView = atom.workspaceView.getActiveView()
      editor = editorView.getEditor()
      statusBar = atom.workspaceView.find('.status-bar').view()
      buffer = editor.getBuffer()

  describe "@initialize", ->
    it "appends only one status bar", ->
      expect(atom.workspaceView.vertical.find('.status-bar').length).toBe 1
      editorView.splitRight()
      expect(atom.workspaceView.vertical.find('.status-bar').length).toBe 1

    it "the status bar is visible by default", ->
      expect(atom.workspaceView.find('.status-bar')).toExist()

  describe ".initialize(editor)", ->
    it "displays the editor's buffer path, cursor buffer position, and buffer modified indicator", ->
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'sample.js'
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''
      expect(StatusBar.cursorPosition.text()).toBe '1,1'

    describe "when associated with an unsaved buffer", ->
      it "displays 'untitled' instead of the buffer's path, but still displays the buffer position", ->
        waitsForPromise ->
          atom.workspace.open()

        runs ->
          StatusBar.activate()
          statusBar = atom.workspaceView.find('.status-bar').view()
          expect(StatusBar.fileInfo.currentPath.text()).toBe 'untitled'
          expect(StatusBar.cursorPosition.text()).toBe '1,1'

  describe ".deactivate()", ->
    it "removes the StatusBarView", ->
      statusBar = atom.workspaceView.find('.status-bar')
      expect(statusBar).toExist()
      expect(atom.workspaceView.statusBar).toBeDefined()

      StatusBar.deactivate()

      statusBar = atom.workspaceView.find('.status-bar')
      expect(statusBar).not.toExist()
      expect(atom.workspaceView.statusBar).toBeFalsy()

    it "can be called twice", ->
      StatusBar.deactivate()
      StatusBar.deactivate()

  describe "when status-bar:toggle is triggered", ->
    it "hides or shows the status bar", ->
      atom.workspaceView.trigger 'status-bar:toggle'
      expect(atom.workspaceView.find('.status-bar')).not.toExist()
      atom.workspaceView.trigger 'status-bar:toggle'
      expect(atom.workspaceView.find('.status-bar')).toExist()

  describe "when the associated editor's path changes", ->
    it "updates the path in the status bar", ->
      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
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

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        editor = atom.workspace.getActiveEditor()
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

      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
        editor = atom.workspace.getActiveEditor()
        editor.insertText("\n")
        advanceClock(buffer.stoppedChangingDelay)
        expect(StatusBar.fileInfo.bufferModified.text()).toBe '*'

    it "doesn't update the buffer modified indicator for the old buffer", ->
      oldBuffer = editor.getBuffer()
      expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
        oldBuffer.setText("new text")
        advanceClock(buffer.stoppedChangingDelay)
        expect(StatusBar.fileInfo.bufferModified.text()).toBe ''

  describe "when the associated editor's cursor position changes", ->
    it "updates the cursor position in the status bar", ->
      atom.workspaceView.attachToDom()
      editor.setCursorScreenPosition([1, 2])
      editorView.updateDisplay()
      expect(StatusBar.cursorPosition.text()).toBe '2,3'

  describe "git branch label", ->
    beforeEach ->
      fs.removeSync(path.join(os.tmpdir(), '.git'))
      atom.workspaceView.attachToDom()

    it "displays the current branch for files in repositories", ->
      atom.project.setPath(atom.project.resolve('git/master.git'))

      waitsForPromise ->
        atom.workspace.open('HEAD')

      runs ->
        expect(StatusBar.git.branchArea).toBeVisible()
        expect(StatusBar.git.branchLabel.text()).toBe 'master'

        atom.workspaceView.getActivePaneView().destroyItems()
        expect(StatusBar.git.branchArea).toBeVisible()
        expect(StatusBar.git.branchLabel.text()).toBe 'master'

      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      atom.workspaceView.getActivePaneView().activateItem(view)
      expect(StatusBar.git.branchArea).not.toBeVisible()

    it "doesn't display the current branch for a file not in a repository", ->
      atom.project.setPath(os.tmpdir())

      waitsForPromise ->
        atom.workspace.open(path.join(os.tmpdir(), 'temp.txt'))

      runs ->
        expect(StatusBar.git.branchArea).toBeHidden()

    it "doesn't display the current branch for a file outside the current project", ->
      waitsForPromise ->
        atom.workspace.open(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))

      runs ->
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

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')

    it "doesn't display the modified icon for an unchanged file", ->
      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveText('')

    it "displays the new icon for a new file", ->
      waitsForPromise ->
        atom.workspace.open(newPath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-added')

    it "displays the ignored icon for an ignored file", ->
      waitsForPromise ->
        atom.workspace.open(ignoredPath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-ignored')

    it "updates when a status-changed event occurs", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')
        fs.writeFileSync(filePath, originalPathText)
        atom.project.getRepo().getPathStatus(filePath)
        expect(StatusBar.git.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "displays the diff stat for new files", ->
      waitsForPromise ->
        atom.workspace.open(newPath)

      runs ->
        expect(StatusBar.git.gitStatusIcon).toHaveText('+1')

    it "does not display for files not in the current project", ->
      waitsForPromise ->
        atom.workspace.open('/tmp/atom-specs/not-in-project.txt')

      runs ->
        expect(StatusBar.git.gitStatusIcon).toBeHidden()

  describe "when the active item view does not implement getCursorBufferPosition()", ->
    it "hides the cursor position view", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editorView.getPane().activateItem(view)
      expect(StatusBar.cursorPosition).toBeHidden()

  describe "when the active item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editorView.getPane().activateItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      expect(StatusBar.fileInfo.currentPath).toBeVisible()

  describe "when the active item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      editorView.getPane().activateItem(view)
      expect(StatusBar.fileInfo.currentPath).toBeHidden()

  describe "when the active item's title changes", ->
    it "updates the path view with the new title", ->
      atom.workspaceView.attachToDom()
      view = $$ -> @div id: 'view', tabindex: -1, 'View'
      view.getTitle = => 'View Title'
      editorView.getPane().activateItem(view)
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'View Title'
      view.getTitle = => 'New Title'
      view.trigger 'title-changed'
      expect(StatusBar.fileInfo.currentPath.text()).toBe 'New Title'
