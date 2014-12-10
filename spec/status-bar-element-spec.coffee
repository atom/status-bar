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

  describe "::addLeftItem(item, {priority})", ->
    it "appends the view for the given item to its left side", ->
      testItem1 = new TestItem(1)
      testItem2 = new TestItem(2)
      testItem3 = new TestItem(3)

      statusBarElement.addLeftItem(testItem1, priority: 10)
      statusBarElement.addLeftItem(testItem2, priority: 30)
      statusBarElement.addLeftItem(testItem3, priority: 20)

      {leftPanel} = statusBarElement

      expect(leftPanel.children[0].nodeName).toBe("ITEM-VIEW")
      expect(leftPanel.children[1].nodeName).toBe("ITEM-VIEW")
      expect(leftPanel.children[2].nodeName).toBe("ITEM-VIEW")

      expect(leftPanel.children[0].model).toBe(testItem1)
      expect(leftPanel.children[1].model).toBe(testItem3)
      expect(leftPanel.children[2].model).toBe(testItem2)

    describe "when no priority is given", ->
      it "appends the item", ->
        testItem1 = new TestItem(1)
        testItem2 = new TestItem(2)

        statusBarElement.addLeftItem(testItem1, priority: 1000)
        statusBarElement.addLeftItem(testItem2)

        {leftPanel} = statusBarElement
        expect(leftPanel.children[0].model).toBe(testItem1)
        expect(leftPanel.children[1].model).toBe(testItem2)

  describe "::addRightItem(item, {priority})", ->
    it "appends the view for the given item to its left side", ->
      testItem1 = new TestItem(1)
      testItem2 = new TestItem(2)
      testItem3 = new TestItem(3)

      statusBarElement.addRightItem(testItem1, priority: 10)
      statusBarElement.addRightItem(testItem2, priority: 30)
      statusBarElement.addRightItem(testItem3, priority: 20)

      {rightPanel} = statusBarElement

      expect(rightPanel.children[0].nodeName).toBe("ITEM-VIEW")
      expect(rightPanel.children[1].nodeName).toBe("ITEM-VIEW")
      expect(rightPanel.children[2].nodeName).toBe("ITEM-VIEW")

      expect(rightPanel.children[0].model).toBe(testItem2)
      expect(rightPanel.children[1].model).toBe(testItem3)
      expect(rightPanel.children[2].model).toBe(testItem1)

    describe "when no priority is given", ->
      it "prepends the item", ->
        testItem1 = new TestItem(1, priority: 1000)
        testItem2 = new TestItem(2)

        statusBarElement.addRightItem(testItem1, priority: 1000)
        statusBarElement.addRightItem(testItem2)

        {rightPanel} = statusBarElement
        expect(rightPanel.children[0].model).toBe(testItem2)
        expect(rightPanel.children[1].model).toBe(testItem1)
