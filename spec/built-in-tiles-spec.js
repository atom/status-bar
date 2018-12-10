const fs = require('fs-plus')
const path = require('path')
const os = require('os')

const {it, fit, ffit, afterEach, beforeEach} = require('./async-spec-helpers') // eslint-disable-line no-unused-vars

describe('Built-in Status Bar Tiles', () => {
  let [statusBar, workspaceElement, dummyView] = []

  beforeEach(async () => {
    workspaceElement = atom.views.getView(atom.workspace)
    dummyView = document.createElement('div')

    await atom.packages.activatePackage('status-bar')
    statusBar = workspaceElement.querySelector('status-bar')
  })

  describe('the file info, cursor and selection tiles', () => {
    let [editor, buffer, fileInfo, cursorPosition, selectionCount] = []

    beforeEach(async () => {
      await atom.workspace.open('sample.js')

      let launchMode // eslint-disable-line no-unused-vars
      [launchMode, fileInfo, cursorPosition, selectionCount] = statusBar.getLeftTiles().map(tile => tile.getItem())
      editor = atom.workspace.getActiveTextEditor()
      buffer = editor.getBuffer()
    })

    describe('when associated with an unsaved buffer', () => {
      it("displays 'untitled' instead of the buffer's path, but still displays the buffer position", async () => {
        await atom.workspace.open()

        atom.views.performDocumentUpdate()
        expect(fileInfo.currentPath.textContent).toBe('untitled')
        expect(cursorPosition.textContent).toBe('1:1')
        expect(selectionCount).toBeHidden()
      })
    })

    describe("when the associated editor's path changes", () => {
      it('updates the path in the status bar', async () => {
        await atom.workspace.open('sample.txt')

        expect(fileInfo.currentPath.textContent).toBe('sample.txt')
      })
    })

    describe('when associated with remote file path', () => {
      beforeEach(() => {
        jasmine.attachToDOM(workspaceElement)
        dummyView.getPath = () => 'remote://server:123/folder/remote_file.txt'
        atom.workspace.getActivePane().activateItem(dummyView)
      })

      it('updates the path in the status bar', () => {
        // The remote path isn't relativized in the test because no remote directory provider is registered.
        expect(fileInfo.currentPath.textContent).toBe('remote://server:123/folder/remote_file.txt')
        expect(fileInfo.currentPath).toBeVisible()
      })

      it('when the path is clicked', () => {
        fileInfo.currentPath.click()
        expect(atom.clipboard.read()).toBe('/folder/remote_file.txt')
      })

      it('calls relativize with the remote URL on shift-click', () => {
        const spy = spyOn(atom.project, 'relativize').andReturn('remote_file.txt')
        const event = new MouseEvent('click', {shiftKey: true})
        fileInfo.currentPath.dispatchEvent(event)
        expect(atom.clipboard.read()).toBe('remote_file.txt')
        expect(spy).toHaveBeenCalledWith('remote://server:123/folder/remote_file.txt')
      })
    })

    describe("when buffer's path is clicked", () => {
      it('copies the absolute path into the clipboard if available', async () => {
        await atom.workspace.open('sample.txt')

        fileInfo.currentPath.click()
        expect(atom.clipboard.read()).toBe(fileInfo.getActiveItem().getPath())
      })
    })

    describe("when buffer's path is shift-clicked", () => {
      it('copies the relative path into the clipboard if available', async () => {
        await atom.workspace.open('sample.txt')

        const event = new MouseEvent('click', {shiftKey: true})
        fileInfo.currentPath.dispatchEvent(event)
        expect(atom.clipboard.read()).toBe('sample.txt')
      })
    })

    describe('when path of an unsaved buffer is clicked', () => {
      it("copies the 'untitled' into clipboard", async () => {
        await atom.workspace.open()

        fileInfo.currentPath.click()
        expect(atom.clipboard.read()).toBe('untitled')
      })
    })

    describe("when buffer's path is not clicked", () => {
      it("doesn't display a path tooltip", async () => {
        jasmine.attachToDOM(workspaceElement)
        await atom.workspace.open()

        expect(document.querySelector('.tooltip')).not.toExist()
      })
    })

    describe("when buffer's path is clicked", () => {
      it('displays path tooltip and the tooltip disappears after ~2 seconds', async () => {
        jasmine.attachToDOM(workspaceElement)
        await atom.workspace.open()

        fileInfo.currentPath.click()
        expect(document.querySelector('.tooltip')).toBeVisible()
        // extra leeway so test won't fail because tooltip disappeared few milliseconds too late
        advanceClock(2100)
        expect(document.querySelector('.tooltip')).not.toExist()
      })
    })

    describe("when saved buffer's path is clicked", () => {
      it("displays a tooltip containing text 'Copied:' and an absolute native path", async () => {
        jasmine.attachToDOM(workspaceElement)
        await atom.workspace.open('sample.txt')

        fileInfo.currentPath.click()
        expect(document.querySelector('.tooltip')).toHaveText(`Copied: ${fileInfo.getActiveItem().getPath()}`)
      })

      it("displays a tooltip containing text 'Copied:' for an absolute Unix path", () => {
        jasmine.attachToDOM(workspaceElement)
        dummyView.getPath = () => '/user/path/for/my/file.txt'
        atom.workspace.getActivePane().activateItem(dummyView)

        fileInfo.currentPath.click()
        expect(document.querySelector('.tooltip')).toHaveText(`Copied: ${dummyView.getPath()}`)
      })

      it("displays a tooltip containing text 'Copied:' for an absolute Windows path", () => {
        jasmine.attachToDOM(workspaceElement)
        dummyView.getPath = () => 'c:\\user\\path\\for\\my\\file.txt'
        atom.workspace.getActivePane().activateItem(dummyView)

        fileInfo.currentPath.click()
        expect(document.querySelector('.tooltip')).toHaveText(`Copied: ${dummyView.getPath()}`)
      })
    })

    describe("when unsaved buffer's path is clicked", () => {
      it("displays a tooltip containing text 'Copied: untitled", async () => {
        jasmine.attachToDOM(workspaceElement)
        await atom.workspace.open()

        fileInfo.currentPath.click()
        expect(document.querySelector('.tooltip')).toHaveText('Copied: untitled')
      })
    })

    describe("when the associated editor's buffer's content changes", () => {
      it('enables the buffer modified indicator', () => {
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
        editor.insertText('\n')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(true)
        editor.backspace()
      })
    })

    describe('when the buffer content has changed from the content on disk', () => {
      it('disables the buffer modified indicator on save', async () => {
        const filePath = path.join(os.tmpdir(), 'atom-whitespace.txt')
        fs.writeFileSync(filePath, '')

        await atom.workspace.open(filePath)

        editor = atom.workspace.getActiveTextEditor()
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
        editor.insertText('\n')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(true)

        await editor.getBuffer().save()

        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
      })

      it('disables the buffer modified indicator if the content matches again', () => {
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
        editor.insertText('\n')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(true)
        editor.backspace()
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
      })

      it('disables the buffer modified indicator when the change is undone', () => {
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
        editor.insertText('\n')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(true)
        editor.undo()
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
      })
    })

    describe('when the buffer changes', () => {
      it('updates the buffer modified indicator for the new buffer', async () => {
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)

        await atom.workspace.open('sample.txt')

        editor = atom.workspace.getActiveTextEditor()
        editor.insertText('\n')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(true)
      })

      it("doesn't update the buffer modified indicator for the old buffer", async () => {
        const oldBuffer = editor.getBuffer()
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)

        await atom.workspace.open('sample.txt')

        oldBuffer.setText('new text')
        advanceClock(buffer.stoppedChangingDelay)
        expect(fileInfo.classList.contains('buffer-modified')).toBe(false)
      })
    })

    describe("when the associated editor's cursor position changes", () => {
      it('updates the cursor position in the status bar', () => {
        jasmine.attachToDOM(workspaceElement)
        editor.setCursorScreenPosition([1, 2])
        atom.views.performDocumentUpdate()
        expect(cursorPosition.textContent).toBe('2:3')
      })

      it('does not throw an exception if the cursor is moved as the result of the active pane item changing to a non-editor (regression)', async () => {
        await atom.packages.deactivatePackage('status-bar')
        atom.workspace.onDidChangeActivePaneItem(() => editor.setCursorScreenPosition([1, 2]))
        await atom.packages.activatePackage('status-bar')
        statusBar = workspaceElement.querySelector('status-bar')
        cursorPosition = statusBar.getLeftTiles()[2].getItem()

        atom.workspace.getActivePane().activateItem(document.createElement('div'))
        expect(editor.getCursorScreenPosition()).toEqual([1, 2])
        atom.views.performDocumentUpdate()
        expect(cursorPosition).toBeHidden()
      })
    })

    describe("when the associated editor's selection changes", () => {
      it('updates the selection count in the status bar', () => {
        jasmine.attachToDOM(workspaceElement)

        editor.setSelectedBufferRange([[0, 0], [0, 0]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('')

        editor.setSelectedBufferRange([[0, 0], [0, 2]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('(1, 2)')

        editor.setSelectedBufferRange([[0, 0], [1, 30]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('(2, 60)')
      })

      it('does not throw an exception if the cursor is moved as the result of the active pane item changing to a non-editor (regression)', async () => {
        await atom.packages.deactivatePackage('status-bar')
        atom.workspace.onDidChangeActivePaneItem(() => editor.setSelectedBufferRange([[1, 2], [1, 3]]))
        await atom.packages.activatePackage('status-bar')
        statusBar = workspaceElement.querySelector('status-bar')
        selectionCount = statusBar.getLeftTiles()[3].getItem()

        atom.workspace.getActivePane().activateItem(document.createElement('div'))
        expect(editor.getSelectedBufferRange()).toEqual([[1, 2], [1, 3]])
        atom.views.performDocumentUpdate()
        expect(selectionCount).toBeHidden()
      })
    })

    describe('when the active pane item does not implement getCursorBufferPosition()', () => {
      it('hides the cursor position view', () => {
        jasmine.attachToDOM(workspaceElement)
        atom.workspace.getActivePane().activateItem(dummyView)
        atom.views.performDocumentUpdate()
        expect(cursorPosition).toBeHidden()
      })
    })

    describe('when the active pane item implements getTitle() but not getPath()', () => {
      it('displays the title', () => {
        jasmine.attachToDOM(workspaceElement)
        dummyView.getTitle = () => 'View Title'
        atom.workspace.getActivePane().activateItem(dummyView)
        expect(fileInfo.currentPath.textContent).toBe('View Title')
        expect(fileInfo.currentPath).toBeVisible()
      })
    })

    describe('when the active pane item neither getTitle() nor getPath()', () => {
      it('hides the path view', () => {
        jasmine.attachToDOM(workspaceElement)
        atom.workspace.getActivePane().activateItem(dummyView)
        expect(fileInfo.currentPath).toBeHidden()
      })
    })

    describe("when the active pane item's title changes", () => {
      it('updates the path view with the new title', () => {
        jasmine.attachToDOM(workspaceElement)
        const callbacks = []
        dummyView.onDidChangeTitle = fn => {
          callbacks.push(fn)
          return {
            dispose () {}
          }
        }
        dummyView.getTitle = () => 'View Title'
        atom.workspace.getActivePane().activateItem(dummyView)
        expect(fileInfo.currentPath.textContent).toBe('View Title')
        dummyView.getTitle = () => 'New Title'
        for (let callback of callbacks) { callback() }
        expect(fileInfo.currentPath.textContent).toBe('New Title')
      })
    })

    describe('the cursor position tile', () => {
      beforeEach(() => atom.config.set('status-bar.cursorPositionFormat', 'foo %L bar %C'))

      it('respects a format string', () => {
        jasmine.attachToDOM(workspaceElement)
        editor.setCursorScreenPosition([1, 2])
        atom.views.performDocumentUpdate()
        expect(cursorPosition.textContent).toBe('foo 2 bar 3')
      })

      it('updates when the configuration changes', () => {
        jasmine.attachToDOM(workspaceElement)
        editor.setCursorScreenPosition([1, 2])
        atom.views.performDocumentUpdate()
        expect(cursorPosition.textContent).toBe('foo 2 bar 3')

        atom.config.set('status-bar.cursorPositionFormat', 'baz %C quux %L')
        atom.views.performDocumentUpdate()
        expect(cursorPosition.textContent).toBe('baz 3 quux 2')
      })

      describe('when clicked', () =>
        it('triggers the go-to-line toggle event', () => {
          const eventHandler = jasmine.createSpy('eventHandler')
          atom.commands.add('atom-text-editor', 'go-to-line:toggle', eventHandler)
          cursorPosition.click()
          expect(eventHandler).toHaveBeenCalled()
        })
      )
    })

    describe('the selection count tile', () => {
      beforeEach(() => atom.config.set('status-bar.selectionCountFormat', '%L foo %C bar selected'))

      it('respects a format string', () => {
        jasmine.attachToDOM(workspaceElement)
        editor.setSelectedBufferRange([[0, 0], [1, 30]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('2 foo 60 bar selected')
      })

      it('updates when the configuration changes', () => {
        jasmine.attachToDOM(workspaceElement)
        editor.setSelectedBufferRange([[0, 0], [1, 30]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('2 foo 60 bar selected')

        atom.config.set('status-bar.selectionCountFormat', 'Selection: baz %C quux %L')
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('Selection: baz 60 quux 2')
      })

      it('does not include the next line if the last selected character is a LF', () => {
        const lineEndingRegExp = /\r\n|\n|\r/g
        buffer = editor.getBuffer()
        buffer.setText(buffer.getText().replace(lineEndingRegExp, '\n'))
        jasmine.attachToDOM(workspaceElement)
        editor.setSelectedBufferRange([[0, 0], [1, 0]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('1 foo 30 bar selected')
      })

      it('does not include the next line if the last selected character is CRLF', () => {
        const lineEndingRegExp = /\r\n|\n|\r/g
        buffer = editor.getBuffer()
        buffer.setText(buffer.getText().replace(lineEndingRegExp, '\r\n'))
        jasmine.attachToDOM(workspaceElement)
        editor.setSelectedBufferRange([[0, 0], [1, 0]])
        atom.views.performDocumentUpdate()
        expect(selectionCount.textContent).toBe('1 foo 31 bar selected')
      })
    })
  })

  describe('the git tile', () => {
    let gitView = null

    const hover = (element, fn) => {
      const hoverDelay = atom.tooltips.hoverDefaults.delay.show
      element.dispatchEvent(new CustomEvent('mouseenter', {bubbles: false}))
      element.dispatchEvent(new CustomEvent('mouseover', {bubbles: true}))
      advanceClock(hoverDelay)
      fn()
      element.dispatchEvent(new CustomEvent('mouseleave', {bubbles: false}))
      element.dispatchEvent(new CustomEvent('mouseout', {bubbles: true}))
      advanceClock(hoverDelay)
    }

    const setupWorkingDir = (name) => {
      const dir = atom.project.getDirectories()[0]
      const target = `${os.tmpdir()}/${name}`
      const targetGit = target + '/.git'
      fs.copySync(dir.resolve('git/working-dir'), path.resolve(target))
      fs.removeSync(path.resolve(targetGit))
      fs.copySync(dir.resolve(`git/${name}.git`), path.resolve(targetGit))
      return target
    }

    beforeEach(() => {
      [gitView] = statusBar.getRightTiles().map(tile => tile.getItem())
    })

    describe('the git ahead/behind count labels', () => {
      beforeEach(() => jasmine.attachToDOM(workspaceElement))

      it('shows the number of commits that can be pushed/pulled', async () => {
        const workingDir = setupWorkingDir('ahead-behind-repo')
        atom.project.setPaths([workingDir])
        const filePath = atom.project.getDirectories()[0].resolve('a.txt')
        const repo = atom.project.getRepositories()[0]

        await atom.workspace.open(filePath)
        await repo.refreshStatus()

        const behindElement = document.body.querySelector('.commits-behind-label')
        const aheadElement = document.body.querySelector('.commits-ahead-label')
        expect(aheadElement).toBeVisible()
        expect(behindElement).toBeVisible()
        expect(aheadElement.textContent).toContain('1')
      })

      it('stays hidden when no commits can be pushed/pulled', async () => {
        const workingDir = setupWorkingDir('no-ahead-behind-repo')
        atom.project.setPaths([workingDir])
        const filePath = atom.project.getDirectories()[0].resolve('a.txt')
        const repo = atom.project.getRepositories()[0]

        await atom.workspace.open(filePath)
        await repo.refreshStatus()

        const behindElement = document.body.querySelector('.commits-behind-label')
        const aheadElement = document.body.querySelector('.commits-ahead-label')
        expect(aheadElement).not.toBeVisible()
        expect(behindElement).not.toBeVisible()
      })
    })

    describe('the git branch label', () => {
      let projectPath = null
      beforeEach(() => {
        projectPath = atom.project.getDirectories()[0].resolve('git/working-dir')
        fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
        jasmine.attachToDOM(workspaceElement)
      })

      afterEach(() => fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git')))

      it('displays the current branch for files in repositories', async () => {
        atom.project.setPaths([projectPath])

        await atom.workspace.open('a.txt')

        const currentBranch = atom.project.getRepositories()[0].getShortHead()
        expect(gitView.branchArea).toBeVisible()
        expect(gitView.branchLabel.textContent).toBe(currentBranch)

        atom.workspace.getActivePane().destroyItems()
        expect(gitView.branchArea).toBeVisible()
        expect(gitView.branchLabel.textContent).toBe(currentBranch)

        atom.workspace.getActivePane().activateItem(dummyView)

        expect(gitView.branchArea).not.toBeVisible()
      })

      it('displays the current branch tooltip', async () => {
        atom.project.setPaths([projectPath])

        await atom.workspace.open('a.txt')

        const currentBranch = atom.project.getRepositories()[0].getShortHead()
        hover(gitView.branchArea, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe(`On branch ${currentBranch}`)
        })
      })

      it("doesn't display the current branch for a file not in a repository", async () => {
        atom.project.setPaths([os.tmpdir()])

        await atom.workspace.open(path.join(os.tmpdir(), 'temp.txt'))

        expect(gitView.branchArea).toBeHidden()
      })

      it("doesn't display the current branch for a file outside the current project", async () => {
        await atom.workspace.open(path.join(os.tmpdir(), 'atom-specs', 'not-in-project.txt'))

        expect(gitView.branchArea).toBeHidden()
      })
    })

    describe('the git status label', () => {
      let [repo, filePath, originalPathText, newPath, ignorePath, ignoredPath, projectPath] = []

      beforeEach(async () => {
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
        jasmine.attachToDOM(workspaceElement)

        repo = atom.project.getRepositories()[0]
        originalPathText = fs.readFileSync(filePath, 'utf8')
        await repo.refreshStatus()
      })

      afterEach(() => {
        fs.writeFileSync(filePath, originalPathText)
        fs.removeSync(newPath)
        fs.removeSync(ignorePath)
        fs.removeSync(ignoredPath)
        fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))
      })

      it('displays the modified icon for a changed file', async () => {
        await atom.workspace.open(filePath)
        fs.writeFileSync(filePath, "i've changed for the worse")
        await repo.refreshStatus()
        expect(gitView.gitStatusIcon).toHaveClass('icon-diff-modified')
      })

      it('displays the 1 line added and not committed tooltip', async () => {
        await atom.workspace.open(filePath)
        fs.writeFileSync(filePath, "i've changed for the worse")
        await repo.refreshStatus()

        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('1 line added to this file not yet committed')
        })
      })

      it('displays the x lines added and not committed tooltip', async () => {
        await atom.workspace.open(filePath)
        fs.writeFileSync(filePath, `i've changed${os.EOL}for the worse`)
        await repo.refreshStatus()

        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('2 lines added to this file not yet committed')
        })
      })

      it("doesn't display the modified icon for an unchanged file", async () => {
        await atom.workspace.open(filePath)
        await repo.refreshStatus()

        expect(gitView.gitStatusIcon).toHaveText('')
      })

      it('displays the new icon for a new file', async () => {
        await atom.workspace.open(newPath)
        await repo.refreshStatus()

        expect(gitView.gitStatusIcon).toHaveClass('icon-diff-added')
        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('1 line in this new file not yet committed')
        })
      })

      it('displays the 1 line added and not committed to new file tooltip', async () => {
        await atom.workspace.open(newPath)
        await repo.refreshStatus()

        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('1 line in this new file not yet committed')
        })
      })

      it('displays the x lines added and not committed to new file tooltip', async () => {
        fs.writeFileSync(newPath, `I'm new${os.EOL}here`)
        await atom.workspace.open(newPath)
        await repo.refreshStatus()

        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('2 lines in this new file not yet committed')
        })
      })

      it('displays the ignored icon for an ignored file', async () => {
        await atom.workspace.open(ignoredPath)

        expect(gitView.gitStatusIcon).toHaveClass('icon-diff-ignored')
        hover(gitView.gitStatusIcon, () => {
          expect(document.body.querySelector('.tooltip').innerText).toBe('File is ignored by git')
        })
      })

      it('updates when a status-changed event occurs', async () => {
        await atom.workspace.open(filePath)
        fs.writeFileSync(filePath, "i've changed for the worse")
        await repo.refreshStatus()
        expect(gitView.gitStatusIcon).toHaveClass('icon-diff-modified')

        fs.writeFileSync(filePath, originalPathText)
        await repo.refreshStatus()
        expect(gitView.gitStatusIcon).not.toHaveClass('icon-diff-modified')
      })

      it('displays the diff stat for modified files', async () => {
        await atom.workspace.open(filePath)
        fs.writeFileSync(filePath, "i've changed for the worse")
        await repo.refreshStatus()
        expect(gitView.gitStatusIcon).toHaveText('+1')
      })

      it('displays the diff stat for new files', async () => {
        await atom.workspace.open(newPath)
        await repo.refreshStatus()

        expect(gitView.gitStatusIcon).toHaveText('+1')
      })

      it('does not display for files not in the current project', async () => {
        await atom.workspace.open('/tmp/atom-specs/not-in-project.txt')

        expect(gitView.gitStatusIcon).toBeHidden()
      })
    })
  })
})
