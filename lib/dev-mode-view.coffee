{$} = require 'space-pen'

class DevModeView extends HTMLElement
  initialize: ->
    @classList.add('inline-block', 'icon', 'icon-color-mode', 'text-error')
    @tooltipDisposable = atom.tooltips.add(this, title: 'This window is in dev mode.')

  detachedCallback: ->
    @tooltipDisposable.dispose()

module.exports = document.registerElement('status-bar-dev-mode', prototype: DevModeView.prototype, extends: 'span')
