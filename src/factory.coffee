Graph = require './graph'
Block = require './block'

class State
  constructor: (@start = [], @end = []) ->

class Factory
  constructor: (@library) ->
    @end()

  snippet: (name, uniforms) ->
    snippet = @library.fetch name
    snippet.apply uniforms

    block = new Block.Shader snippet

    @append block.node

  append: (node) ->
    @graph.add node

    end.connect(node) for end in @_state.end

    @_state.start = [node] if !@_state.start.length
    @_state.end = [node]

    @

  prepend: (node) ->
    @graph.add node

    node.connect(start) for start in @_state.start

    @_state.end = [node] if !@_state.end.length
    @_state.start = [node]

    @

  group: () ->
    @_push()
    @_push()

  pass: () ->
    @next()

    @_state.start.push null
    @combine()

  next: () ->
    sub = @_pop()

    @_state.start = @_state.start.concat sub.start
    @_state.end   = @_state.end.concat sub.end

    @_push()

  combine: () ->
    throw "Popping factory stack too far" if @_stack.length <= 2

    @next()._pop()

    sub = @_pop()
    main = @_state

    if sub.start.length
      for to in sub.start
        # Passthrough all input nodes to other side
        if !to
          sub.end = sub.end.concat main.end

        # Normal destination
        else
          from.connect to, true for from in main.end

    main.end = sub.end
    @

  end: () ->
    graph = @graph;

    @graph = new Graph.Graph();
    @_state = new State
    @_stack = [@_state]
    @group()

    # Add compile shortcut.
    if graph
      graph.compile = () ->
        graph.tail().owner.compile()

    graph

  compile: () ->
    @end().compile()

  _push: () ->
    @_stack.unshift new State
    @_state = @_stack[0]
    @

  _pop: () ->
    @_state = @_stack[1]
    @_stack.shift
    @


module.exports = Factory