{$} = require 'atom'

module.exports =
class DevModeView extends HTMLElement
  initialize: ->
    @classList.add('inline-block', 'icon', 'icon-color-mode', 'text-error')
    $(this).setTooltip('This window is in dev mode.')

module.exports = document.registerElement('status-bar-dev-mode', prototype: DevModeView.prototype, extends: 'span')
