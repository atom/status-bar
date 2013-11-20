{_, $, $$, View} = require 'atom'

module.exports =
class GrammarView extends View
  @content: ->
    @a href: '#', class: 'grammar-name inline-block'

  initialize: (@statusBar) ->
    @subscribe @statusBar, 'active-buffer-changed', @updateGrammarText

    @subscribe this, 'click', => @getActiveView().trigger('grammar-selector:show'); false
    @subscribe rootView, 'editor:grammar-changed', @updateGrammarText

  afterAttach: ->
    @updateGrammarText()

  getActiveView: ->
    atom.rootView.getActiveView()

  updateGrammarText: =>
    grammar = @getActiveView()?.getGrammar?()
    if grammar?
      if grammar is syntax.nullGrammar
        grammarName = 'Plain Text'
      else
        grammarName = grammar.name
      @text(grammarName).show()
    else
      @hide()
