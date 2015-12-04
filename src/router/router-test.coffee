Router = require "./router"
assert = require "assert"

describe "Stomp Router", ->
  beforeEach ->
    @router = new Router()

  it "should dispatch routes in series", (done) ->
    @router.use (context, next) ->
      context.ok = true
      next()
    @router.use (context, next) ->
      assert context.ok
      next()
    @router.dispatch({}, done)

  it "should match on path", (done) ->
    @router.use "/some/path", ->
      assert.fail()
    @router.dispatch({ headers: {} }, done)

  it "should add path params", (done) ->
    @router.use "/users/:id", (context, next) ->
      assert.equal context.params.id, "5"
      next()
    headers = { "destination": "/users/5" }
    @router.dispatch({ headers }, done)

  it "should match on command", (done) ->
    @router.subscribe "/message", (context, next) ->
      assert.fail()
      
    @router.send "/message", (context, next) ->
      next()
      
    context =
      command: "SEND"
      headers: { "destination": "/message" }
    @router.dispatch(context, done)

  it "should mount routers", (done) ->
    subrouter = new Router()
    subrouter.use (context, next) ->
      context.ok = true
      next()
    
    @router .use subrouter
    
    @router.use (context, next) ->
      assert context.ok
      next()
    
    @router.dispatch({}, done)


