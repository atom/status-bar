# Status Bar package

Display information about the current editor such as cursor position, file path,
grammar, current branch, ahead/behind commit counts, and line diff count.

![](https://f.cloud.github.com/assets/671378/2241819/f8418cb8-9ce5-11e3-87e5-109e965986d0.png)

## API

This package adds a `status-bar` element to the atom workspace.

You can access it from your package by doing the following:

```coffee
module.exports =
  activate: ->
    atom.packages.once 'activated', ->
      statusBar = document.querySelector("status-bar")
      if statusBar?
        @statusBarTile = statusBar.addLeftTile(item: myElement, priority: 100)
  
  deactivate: ->
    @statusBarTile?.destroy()
```

It is important to check that the `status-bar` element is present,
since the status bar package could be disabled or not installed.

The `status-bar` element has four methods:

  * `addLeftTile({ item, priority })` - Add a tile to the left side of the status bar. Lower priority tiles are placed further to the left. 
  * `addRightTile({ item, priority })` - Add a tile to the right side of the status bar. Lower priority tiles are placed further to the right. 

The `item` parameter to these methods can be a DOM element, a [jQuery object](http://jquery.com), or a model object for which a view provider has been
registered in the [the view registry](https://atom.io/docs/api/latest/ViewRegistry).

  * `getLeftTiles()` - Retrieve all of the tiles on the left side of the status bar.
  * `getRightTiles()` - Retrieve all of the tiles on the right side of the status bar

All of these methods return `Tile` objects, which have the following methods:
  * `getPriority()` - Retrieve the priority that was assigned to the `Tile` when it was created.
  * `getItem()` - Retrieve the `Tile`'s item.
  * `destroy()` - Remove the `Tile` from the status bar.
