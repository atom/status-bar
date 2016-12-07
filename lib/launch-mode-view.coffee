class LaunchModeView extends HTMLElement
  initialize: ({safeMode, devMode}={}) ->
    @classList.add('inline-block', 'icon')
    if devMode
      @classList.add('text-error', 'icon-microscope')
      @tooltipDisposable = atom.tooltips.add(this, title: 'This window is in dev mode')
    else if safeMode
      @classList.add('text-success', 'icon-jersey')
      @tooltipDisposable = atom.tooltips.add(this, title: 'This window is in safe mode')

  detachedCallback: ->
    @tooltipDisposable?.dispose()

module.exports = document.registerElement('status-bar-launch-mode', prototype: LaunchModeView.prototype, extends: 'span')
