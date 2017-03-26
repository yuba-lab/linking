import \./class-creator : class-creator

empty = {}
function pass => it
function flat-diff a, b
  return false if a == b
  return true if typeof a != \object or typeof b != \object
  keys = Object.keys a
  return true if keys.length != Object.keys b .length
  keys.some -> a[it] != b[it]
function name => it && (it.display-name || it.name || 'no name')

!function notify listeners
  Array.from listeners.keys! .map (update) -> update!

function handle-change select, props
  if flat-diff @selected, next = select @store.getState!, props
    @selected = next
    @changed = true
  else notify @listeners

function set-context self, store
  self.source = {store}
  self.get-child-context = -> @source

!function mount select
  @store = @props.store || @context.store
  @selected = select @store.getState!, @props
  if select == pass
    set-context @, @store
    return

  listeners = @listeners = new Set
  function subscribe update
    listeners.add update
    listeners.delete.bind listeners, update

  set-context @, {...@store, subscribe}

function listen-store select
  componentDidMount: -> @off = @store.subscribe ~>
    handle-change.call @, select, @props and @setState empty
  componentWillUnmount: -> @off!

function handle-props select, merge
  componentWillReceiveProps: (next-props) ->
    handle-change.call @, select, next-props if select != pass
    @changed ||= merge.length > 2 && flat-diff next-props, @props
  shouldComponentUpdate: -> @changed

function chain select, merge, render
  hooks = if select == pass then {} else listen-store select
  if select != pass || merge.length > 2
    Object.assign hooks, handle-props select, merge

  hooks <<<
    display-name: "linking #{name render}: " + [select, merge]map name
    componentWillMount: -> mount.call @, select
    render: ->
      @changed = false
      render merge @selected, @store.dispatch, @props

function link {create-element: h, Component, PropTypes, \
    create-class=class-creator Component}
  if PropTypes?any
    context-types = store: that
    types = contextTypes: context-types, childContextTypes: context-types

  (render, select=pass, merge=pass) ->
    linking = chain select, merge, render
    h.bind void create-class {} <<< types <<< linking

export {default: link, link}
