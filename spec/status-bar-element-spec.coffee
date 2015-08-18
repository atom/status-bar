StatusBarElement = require '../lib/status-bar-view'

describe "StatusBarElement", ->
  statusBarElement = null

  class TestItem
    constructor: (@id) ->

  beforeEach ->
    statusBarElement = new StatusBarElement().initialize()

    atom.views.addViewProvider TestItem, (model) ->
      element = document.createElement("item-view")
      element.model = model
      element

  describe "::addLeftTile({item, priority})", ->
    it "appends the view for the given item to its left side", ->
      testItem1 = new TestItem(1)
      testItem2 = new TestItem(2)
      testItem3 = new TestItem(3)

      tile1 = statusBarElement.addLeftTile(item: testItem1, priority: 10)
      tile2 = statusBarElement.addLeftTile(item: testItem2, priority: 30)
      tile3 = statusBarElement.addLeftTile(item: testItem3, priority: 20)

      {leftPanel} = statusBarElement

      expect(leftPanel.children[0].nodeName).toBe("ITEM-VIEW")
      expect(leftPanel.children[1].nodeName).toBe("ITEM-VIEW")
      expect(leftPanel.children[2].nodeName).toBe("ITEM-VIEW")

      expect(leftPanel.children[0].model).toBe(testItem1)
      expect(leftPanel.children[1].model).toBe(testItem3)
      expect(leftPanel.children[2].model).toBe(testItem2)

      expect(statusBarElement.getLeftTiles()).toEqual([tile1, tile3, tile2])
      expect(tile1.getPriority()).toBe(10)
      expect(tile1.getItem()).toBe(testItem1)

    it "allows the view to be removed", ->
      testItem = new TestItem(1)
      tile = statusBarElement.addLeftTile(item: testItem, priority: 10)
      tile.destroy()
      expect(statusBarElement.leftPanel.children.length).toBe(0)

      statusBarElement.addLeftTile(item: testItem, priority: 9)

    describe "when no priority is given", ->
      it "appends the item", ->
        testItem1 = new TestItem(1)
        testItem2 = new TestItem(2)

        statusBarElement.addLeftTile(item: testItem1, priority: 1000)
        statusBarElement.addLeftTile(item: testItem2)

        {leftPanel} = statusBarElement
        expect(leftPanel.children[0].model).toBe(testItem1)
        expect(leftPanel.children[1].model).toBe(testItem2)

  describe "::addRightTile({item, priority})", ->
    it "appends the view for the given item to its right side", ->
      testItem1 = new TestItem(1)
      testItem2 = new TestItem(2)
      testItem3 = new TestItem(3)

      tile1 = statusBarElement.addRightTile(item: testItem1, priority: 10)
      tile2 = statusBarElement.addRightTile(item: testItem2, priority: 30)
      tile3 = statusBarElement.addRightTile(item: testItem3, priority: 20)

      {rightPanel} = statusBarElement

      expect(rightPanel.children[0].nodeName).toBe("ITEM-VIEW")
      expect(rightPanel.children[1].nodeName).toBe("ITEM-VIEW")
      expect(rightPanel.children[2].nodeName).toBe("ITEM-VIEW")

      expect(rightPanel.children[0].model).toBe(testItem2)
      expect(rightPanel.children[1].model).toBe(testItem3)
      expect(rightPanel.children[2].model).toBe(testItem1)

      expect(statusBarElement.getRightTiles()).toEqual([tile2, tile3, tile1])
      expect(tile1.getPriority()).toBe(10)
      expect(tile1.getItem()).toBe(testItem1)

    it "allows the view to be removed", ->
      testItem = new TestItem(1)
      disposable = statusBarElement.addRightTile(item: testItem, priority: 10)
      disposable.destroy()
      expect(statusBarElement.rightPanel.children.length).toBe(0)

      statusBarElement.addRightTile(item: testItem, priority: 11)

    describe "when no priority is given", ->
      it "prepends the item", ->
        testItem1 = new TestItem(1, priority: 1000)
        testItem2 = new TestItem(2)

        statusBarElement.addRightTile(item: testItem1, priority: 1000)
        statusBarElement.addRightTile(item: testItem2)

        {rightPanel} = statusBarElement
        expect(rightPanel.children[0].model).toBe(testItem2)
        expect(rightPanel.children[1].model).toBe(testItem1)
