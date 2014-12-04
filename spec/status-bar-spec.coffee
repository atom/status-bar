{WorkspaceView} = require 'atom'
fs = require 'fs-plus'
path = require 'path'
os = require 'os'

describe "Status Bar package", ->
  [editor, editorView, statusBar, buffer, workspaceElement, dummyView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.workspaceView = new WorkspaceView

    dummyView = document.createElement("div")

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    runs ->
      atom.workspaceView.simulateDomAttachment()
      statusBar = atom.packages.getActivePackage('status-bar').mainModule
      editorView = atom.workspaceView.getActiveView()
      editor = editorView.getEditor()
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
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'sample.js'
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''
      expect(statusBar.cursorPosition.textContent).toBe '1,1'
      expect(statusBar.selectionCount).toBeHidden()

    describe "when associated with an unsaved buffer", ->
      it "displays 'untitled' instead of the buffer's path, but still displays the buffer position", ->
        waitsForPromise ->
          atom.workspace.open()

        runs ->
          expect(statusBar.fileInfo.currentPath.textContent).toBe 'untitled'
          expect(statusBar.cursorPosition.textContent).toBe '1,1'
          expect(statusBar.selectionCount).toBeHidden()

  describe ".deactivate()", ->
    it "removes the StatusBarView", ->
      statusBarView = atom.workspaceView.find('.status-bar')
      expect(statusBarView).toExist()
      expect(atom.workspaceView.statusBar).toBeDefined()

      statusBar.deactivate()

      statusBarView = atom.workspaceView.find('.status-bar')
      expect(statusBarView).not.toExist()
      expect(atom.workspaceView.statusBar).toBeFalsy()

    it "can be called twice", ->
      statusBar.deactivate()
      statusBar.deactivate()

  describe "when status-bar:toggle is triggered", ->
    beforeEach ->
      jasmine.attachToDOM(workspaceElement)

    it "hides or shows the status bar", ->
      atom.workspaceView.trigger 'status-bar:toggle'
      expect(workspaceElement.querySelector('.status-bar').parentNode).not.toBeVisible()
      atom.workspaceView.trigger 'status-bar:toggle'
      expect(workspaceElement.querySelector('.status-bar').parentNode).toBeVisible()

  describe "when the associated editor's path changes", ->
    it "updates the path in the status bar", ->
      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
        expect(statusBar.fileInfo.currentPath.textContent).toBe 'sample.txt'

  describe "when the associated editor's buffer's content changes", ->
    it "enables the buffer modified indicator", ->
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.fileInfo.bufferModified.textContent).toBe '*'
      editor.backspace()

  describe "when the buffer content has changed from the content on disk", ->
    it "disables the buffer modified indicator on save", ->
      filePath = path.join(os.tmpdir(), "atom-whitespace.txt")
      fs.writeFileSync(filePath, "")

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        editor = atom.workspace.getActiveEditor()
        expect(statusBar.fileInfo.bufferModified.textContent).toBe ''
        editor.insertText("\n")
        advanceClock(buffer.stoppedChangingDelay)
        expect(statusBar.fileInfo.bufferModified.textContent).toBe '*'
        editor.getBuffer().save()
        expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

    it "disables the buffer modified indicator if the content matches again", ->
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.fileInfo.bufferModified.textContent).toBe '*'
      editor.backspace()
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

    it "disables the buffer modified indicator when the change is undone", ->
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''
      editor.insertText("\n")
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.fileInfo.bufferModified.textContent).toBe '*'
      editor.undo()
      advanceClock(buffer.stoppedChangingDelay)
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

  describe "when the buffer changes", ->
    it "updates the buffer modified indicator for the new buffer", ->
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
        editor = atom.workspace.getActiveEditor()
        editor.insertText("\n")
        advanceClock(buffer.stoppedChangingDelay)
        expect(statusBar.fileInfo.bufferModified.textContent).toBe '*'

    it "doesn't update the buffer modified indicator for the old buffer", ->
      oldBuffer = editor.getBuffer()
      expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

      waitsForPromise ->
        atom.workspace.open('sample.txt')

      runs ->
        oldBuffer.setText("new text")
        advanceClock(buffer.stoppedChangingDelay)
        expect(statusBar.fileInfo.bufferModified.textContent).toBe ''

  describe "when the associated editor's cursor position changes", ->
    it "updates the cursor position in the status bar", ->
      atom.workspaceView.attachToDom()
      editor.setCursorScreenPosition([1, 2])
      expect(statusBar.cursorPosition.textContent).toBe '2,3'

  describe "when the associated editor's selection changes", ->
    it "updates the selection count in the status bar", ->
      atom.workspaceView.attachToDom()
      editorView.height(100)
      editorView.component.pollDOM()

      editor.setSelectedBufferRange([[0, 0], [0, 2]])
      expect(statusBar.selectionCount.textContent).toBe '(2)'

  describe "git branch label", ->
    beforeEach ->
      fs.removeSync(path.join(os.tmpdir(), '.git'))
      atom.workspaceView.attachToDom()

    it "displays the current branch for files in repositories", ->
      atom.project.setPath(atom.project.resolve('git/master.git'))

      waitsForPromise ->
        atom.workspace.open('HEAD')

      runs ->
        expect(statusBar.git.branchArea).toBeVisible()
        expect(statusBar.git.branchLabel.textContent).toBe 'master'

        atom.workspaceView.getActivePaneView().destroyItems()
        expect(statusBar.git.branchArea).toBeVisible()
        expect(statusBar.git.branchLabel.textContent).toBe 'master'

      atom.workspaceView.getActivePaneView().activateItem(dummyView)
      expect(statusBar.git.branchArea).not.toBeVisible()

    it "doesn't display the current branch for a file not in a repository", ->
      atom.project.setPath(os.tmpdir())

      waitsForPromise ->
        atom.workspace.open(path.join(os.tmpdir(), 'temp.txt'))

      runs ->
        expect(statusBar.git.branchArea).toBeHidden()

    it "doesn't display the current branch for a file outside the current project", ->
      waitsForPromise ->
        atom.workspace.open(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))

      runs ->
        expect(statusBar.git.branchArea).toBeHidden()

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
        expect(statusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')

    it "doesn't display the modified icon for an unchanged file", ->
      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveText('')

    it "displays the new icon for a new file", ->
      waitsForPromise ->
        atom.workspace.open(newPath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveClass('icon-diff-added')

    it "displays the ignored icon for an ignored file", ->
      waitsForPromise ->
        atom.workspace.open(ignoredPath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveClass('icon-diff-ignored')

    it "updates when a status-changed event occurs", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')
        fs.writeFileSync(filePath, originalPathText)
        atom.project.getRepo().getPathStatus(filePath)
        expect(statusBar.git.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepo().getPathStatus(filePath)

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveText('+1')

    it "displays the diff stat for new files", ->
      waitsForPromise ->
        atom.workspace.open(newPath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveText('+1')

    it "does not display for files not in the current project", ->
      waitsForPromise ->
        atom.workspace.open('/tmp/atom-specs/not-in-project.txt')

      runs ->
        expect(statusBar.git.gitStatusIcon).toBeHidden()

  describe "when the active item view does not implement getCursorBufferPosition()", ->
    it "hides the cursor position view", ->
      atom.workspaceView.attachToDom()
      editorView.getPane().activateItem(dummyView)
      expect(statusBar.cursorPosition).toBeHidden()

  describe "when the active item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      atom.workspaceView.attachToDom()
      dummyView.getTitle = => 'View Title'
      editorView.getPane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'View Title'
      expect(statusBar.fileInfo.currentPath).toBeVisible()

  describe "when the active item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      atom.workspaceView.attachToDom()
      editorView.getPane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath).toBeHidden()

  describe "when the active item's title changes", ->
    it "updates the path view with the new title", ->
      atom.workspaceView.attachToDom()
      callbacks = []
      dummyView.onDidChangeTitle = (fn) ->
        callbacks.push(fn)
        {dispose: ->}
      dummyView.getTitle = -> 'View Title'
      editorView.getPane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'View Title'
      dummyView.getTitle = -> 'New Title'
      callback() for callback in callbacks
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'New Title'
