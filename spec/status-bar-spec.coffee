describe "Status Bar package", ->
  [editor, statusBar, statusBarService, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.packages.activatePackage('status-bar').then (pack) ->
        statusBar = workspaceElement.querySelector("status-bar")
        statusBarService = pack.mainModule.provideStatusBar()

  describe "@activate()", ->
    it "appends only one status bar", ->
      expect(workspaceElement.querySelectorAll('status-bar').length).toBe 1
      atom.workspace.getActivePane().splitRight(copyActiveItem: true)
      expect(workspaceElement.querySelectorAll('status-bar').length).toBe 1

  describe "@deactivate()", ->
    it "removes the status bar view", ->
      atom.packages.deactivatePackage("status-bar")
      expect(workspaceElement.querySelector('status-bar')).toBeNull()

  describe "when status-bar:toggle is triggered", ->
    beforeEach ->
      jasmine.attachToDOM(workspaceElement)

    it "hides or shows the status bar", ->
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
      expect(workspaceElement.querySelector('status-bar').parentNode).not.toBeVisible()
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
      expect(workspaceElement.querySelector('status-bar').parentNode).toBeVisible()

  describe "the 'status-bar' service", ->
    it "allows tiles to be added, removed, and retrieved", ->
      dummyView = document.createElement("div")
      tile = statusBarService.addLeftTile(item: dummyView)
      expect(statusBar).toContain(dummyView)
      expect(statusBarService.getLeftTiles()).toContain(tile)
      tile.destroy()
      expect(statusBar).not.toContain(dummyView)
      expect(statusBarService.getLeftTiles()).not.toContain(tile)

      dummyView = document.createElement("div")
      tile = statusBarService.addRightTile(item: dummyView)
      expect(statusBar).toContain(dummyView)
      expect(statusBarService.getRightTiles()).toContain(tile)
      tile.destroy()
      expect(statusBar).not.toContain(dummyView)
      expect(statusBarService.getRightTiles()).not.toContain(tile)

    it "allows the git info tile to be disabled", ->
      getGitInfoTile = ->
        statusBar.getRightTiles().find((tile) -> tile.item.matches('.git-view'))

      expect(getGitInfoTile()).not.toBeUndefined()
      statusBarService.disableGitInfoTile()
      expect(getGitInfoTile()).toBeUndefined()
