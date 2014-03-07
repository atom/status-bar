# Status Bar package

Display information about the current editor such as cursor position, file path,
grammar, current branch, ahead/behind commit counts, and line diff count.

![](https://f.cloud.github.com/assets/671378/2241819/f8418cb8-9ce5-11e3-87e5-109e965986d0.png)

## API

The status bar exposes a `atom.workspaceView.statusBar` global that exposes an
API to add views to the status bar.

You can access it from your package by doing the following:

```coffee
module.exports =
  activate: ->
    atom.packages.once 'activated', ->
      atom.workspaceView.statusBar?.appendLeft('<span>hi!<span>')
```

It is important to guard against the `atom.workspaceView.statusBar` property
being `null` since the status bar package could be disabled or not installed.

The status bar API has 4 methods:

  * `appendLeft(view)` - Append a view to the left side of the status bar
  * `prependLeft(view)` - Prepend a view to the left side of the status bar
  * `appendRight(view)` - Append a view to the right side of the status bar
  * `prependRight(view)` - Prepend a view to the right side of the status bar

The `view` parameter to all these methods can be a [jQuery](http://jquery.com)
selector, [Space Pen](https://github.com/atom/space-pen) view, string of HTML,
or DOM element.
