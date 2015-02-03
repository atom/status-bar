Grim = require 'grim'
fs = require 'fs-plus'
path = require 'path'
os = require 'os'

describe "Status Bar package", ->
  [editor, statusBar, buffer, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.__workspaceView = {}

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

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

  describe "@deactivate()", ->
    it "removes the status bar view", ->
      atom.packages.deactivatePackage("status-bar")
      expect(workspaceElement.querySelector('.status-bar')).toBeNull()
      expect(atom.__workspaceView.statusBar).toBeFalsy()

  describe "when status-bar:toggle is triggered", ->
    beforeEach ->
      jasmine.attachToDOM(workspaceElement)

    it "hides or shows the status bar", ->
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
      expect(workspaceElement.querySelector('.status-bar').parentNode).not.toBeVisible()
      atom.commands.dispatch(workspaceElement, 'status-bar:toggle')
      expect(workspaceElement.querySelector('.status-bar').parentNode).toBeVisible()
