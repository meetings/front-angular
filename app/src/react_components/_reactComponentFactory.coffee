class ReactComponentFactory
  @createFactory: (name, namespace, reactClass) ->
    if namespace?
      React.DOM[namespace] ?= []
      React.DOM[namespace][name] = React.createFactory(
        React.createClass(reactClass)
      )
    else
      React.DOM[name] = React.createFactory(
        React.createClass(reactClass)
      )
