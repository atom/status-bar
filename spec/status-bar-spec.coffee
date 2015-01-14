Grim = require 'grim'
fs = require 'fs-plus'
path = require 'path'
os = require 'os'

describe "Status Bar package", ->
  [editor, statusBar, buffer, workspaceElement, dummyView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.__workspaceView = {}

    dummyView = document.createElement("div")

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    runs ->
      statusBar = atom.packages.getActivePackage('status-bar').mainModule
      editor = atom.workspace.getActiveTextEditor()
      buffer = editor.getBuffer()

  describe "@activate", ->
    it "appends only one status bar", ->
      expect(workspaceElement.querySelectorAll('.status-bar').length).toBe 1
      atom.workspace.getActivePane().splitRight(copyActiveItem: true)
      expect(workspaceElement.querySelectorAll('.status-bar').length).toBe 1

    it "makes the status bar available as a deprecated property on atom.workspaceView", ->
      spyOn(Grim, 'deprecate')
      expect(atom.__workspaceView.statusBar[0]).toBe(workspaceElement.querySelector(".status-bar"))
      expect(atom.__workspaceView.statusBar[0]).toBe(workspaceElement.querySelector("status-bar"))
      expect(Grim.deprecate).toHaveBeenCalled()

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

  describe "@deactivate()", ->
    it "removes the status bar view", ->
      statusBar.deactivate()
      expect(workspaceElement.querySelector('.status-bar')).toBeNull()
      expect(atom.__workspaceView.statusBar).toBeFalsy()

    it "can be called twice", ->
      statusBar.deactivate()
      statusBar.deactivate()

  describe "when status-bar:toggle is triggered", ->
    beforeEach ->
      jasmine.attachToDOM(workspaceElement)

    it "hides or shows the status bar", ->
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
      expect(workspaceElement.querySelector('.status-bar').parentNode).not.toBeVisible()
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
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
        editor = atom.workspace.getActiveTextEditor()
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
        editor = atom.workspace.getActiveTextEditor()
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
      jasmine.attachToDOM(workspaceElement)
      editor.setCursorScreenPosition([1, 2])
      expect(statusBar.cursorPosition.textContent).toBe '2,3'

  describe "when the associated editor's selection changes", ->
    it "updates the selection count in the status bar", ->
      jasmine.attachToDOM(workspaceElement)

      editor.setSelectedBufferRange([[0, 0], [0, 2]])
      expect(statusBar.selectionCount.textContent).toBe '(2)'

  describe "git branch label", ->
    beforeEach ->
      fs.removeSync(path.join(os.tmpdir(), '.git'))
      jasmine.attachToDOM(workspaceElement)

    it "displays the current branch for files in repositories", ->
      atom.project.setPaths([atom.project.getDirectories()[0].resolve('git/master.git')])

      waitsForPromise ->
        atom.workspace.open('HEAD')

      runs ->
        expect(statusBar.git.branchArea).toBeVisible()
        expect(statusBar.git.branchLabel.textContent).toBe 'master'

        atom.workspace.getActivePane().destroyItems()
        expect(statusBar.git.branchArea).toBeVisible()
        expect(statusBar.git.branchLabel.textContent).toBe 'master'

      atom.workspace.getActivePane().activateItem(dummyView)
      expect(statusBar.git.branchArea).not.toBeVisible()

    it "doesn't display the current branch for a file not in a repository", ->
      atom.project.setPaths([os.tmpdir()])

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
      projectPath = atom.project.getDirectories()[0].resolve('git/working-dir')
      fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
      atom.project.setPaths([projectPath])
      filePath = atom.project.getDirectories()[0].resolve('a.txt')
      newPath = atom.project.getDirectories()[0].resolve('new.txt')
      fs.writeFileSync(newPath, "I'm new here")
      ignorePath = path.join(projectPath, '.gitignore')
      fs.writeFileSync(ignorePath, 'ignored.txt')
      ignoredPath = path.join(projectPath, 'ignored.txt')
      fs.writeFileSync(ignoredPath, '')
      atom.project.getRepositories()[0].getPathStatus(filePath)
      atom.project.getRepositories()[0].getPathStatus(newPath)
      originalPathText = fs.readFileSync(filePath, 'utf8')
      jasmine.attachToDOM(workspaceElement)

    afterEach ->
      fs.writeFileSync(filePath, originalPathText)
      fs.removeSync(newPath)
      fs.removeSync(ignorePath)
      fs.removeSync(ignoredPath)
      fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

    it "displays the modified icon for a changed file", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepositories()[0].getPathStatus(filePath)

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
      atom.project.getRepositories()[0].getPathStatus(filePath)

      waitsForPromise ->
        atom.workspace.open(filePath)

      runs ->
        expect(statusBar.git.gitStatusIcon).toHaveClass('icon-diff-modified')
        fs.writeFileSync(filePath, originalPathText)
        atom.project.getRepositories()[0].getPathStatus(filePath)
        expect(statusBar.git.gitStatusIcon).not.toHaveClass('icon-diff-modified')

    it "displays the diff stat for modified files", ->
      fs.writeFileSync(filePath, "i've changed for the worse")
      atom.project.getRepositories()[0].getPathStatus(filePath)

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

  describe "when the active pane item does not implement getCursorBufferPosition()", ->
    it "hides the cursor position view", ->
      jasmine.attachToDOM(workspaceElement)
      atom.workspace.getActivePane().activateItem(dummyView)
      expect(statusBar.cursorPosition).toBeHidden()

  describe "when the active pane item implements getTitle() but not getPath()", ->
    it "displays the title", ->
      jasmine.attachToDOM(workspaceElement)
      dummyView.getTitle = => 'View Title'
      atom.workspace.getActivePane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'View Title'
      expect(statusBar.fileInfo.currentPath).toBeVisible()

  describe "when the active pane item neither getTitle() nor getPath()", ->
    it "hides the path view", ->
      jasmine.attachToDOM(workspaceElement)
      atom.workspace.getActivePane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath).toBeHidden()

  describe "when the active pane item's title changes", ->
    it "updates the path view with the new title", ->
      jasmine.attachToDOM(workspaceElement)
      callbacks = []
      dummyView.onDidChangeTitle = (fn) ->
        callbacks.push(fn)
        {dispose: ->}
      dummyView.getTitle = -> 'View Title'
      atom.workspace.getActivePane().activateItem(dummyView)
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'View Title'
      dummyView.getTitle = -> 'New Title'
      callback() for callback in callbacks
      expect(statusBar.fileInfo.currentPath.textContent).toBe 'New Title'
