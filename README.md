# Status Bar package [![Build Status](https://travis-ci.org/atom/status-bar.svg?branch=master)](https://travis-ci.org/atom/status-bar)

Display information about the current editor such as cursor position, file path,
grammar, current branch, ahead/behind commit counts, and line diff count.

![](https://f.cloud.github.com/assets/671378/2241819/f8418cb8-9ce5-11e3-87e5-109e965986d0.png)

## Configuration

The status-bar package accepts the following configuration values:

* `status-bar.cursorPositionFormat` and `status-bar.cursorPositionTooltipFormat` &mdash; These strings describe the format to use for the cursor position status bar tile and tooltip. The format strings accept the following interpolations
    * `%L` is replaced by the 1-based line number.
    * `%C` is replaced by the 1-based column number.
    * `%l` is replaced by the number of lines in the file.
    * `%z` is replaced by the size (number of characters) of the file.
    * `%o` is replaced by the character offset of the cursor.
    * `%p` is replaced by the offset divided the size as a percent.

## API

This package provides a service that you can use in other Atom packages. To use
it, include `status-bar` in the `consumedServices` section of your `package.json`:

```json
{
  "name": "my-package",
  "consumedServices": {
    "status-bar": {
      "versions": {
        "^1.0.0": "consumeStatusBar"
      }
    }
  }
}
```

Then, in your package's main module, call methods on the service:

```coffee
module.exports =
  activate: -> # ...

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile(item: myElement, priority: 100)

  deactivate: ->
    # ...
    @statusBarTile?.destroy()
    @statusBarTile = null
```

The `status-bar` API has four methods:

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
