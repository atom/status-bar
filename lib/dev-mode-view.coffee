{View} = require 'atom'

module.exports =
class DevModeView extends View
  @content: ->
    @span class: 'inline-block icon icon-primitive-square text-error'
