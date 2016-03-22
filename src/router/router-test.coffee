Router = require "./router"
assert = require "assert"

describe "Router", ->
  beforeEach ->
    @router = new Router()

  it "should dispatch routes in series", (done) ->
    @router.use (next) ->
      @ok = true
      next()
    @router.use (next) ->
      assert @ok
      next()
    @router.dispatch({}, done)
  
  it "should match on path", (done) ->
    @router.use "/some/path", (next) ->
      assert.fail()
    @router.dispatch({ headers: {} }, done)

  it "should add path params", (done) ->
    @router.use "/users/:id", (next) ->
      assert.equal @params.id, "5"
      next()
    headers = { "destination": "/users/5" }
    @router.dispatch({ headers }, done)

  it "should match on command", (done) ->
    @router.subscribe (next) ->
      assert.fail("invalid path")
    
    @router.connect (next) ->
      @state.ok = true
      next()
    
    @router.use (next) ->
      assert @state.ok
      next()
    
    context = 
      command: "CONNECT"
      headers: {}
      state: {}
    
    @router.dispatch(context, done)

  it "should match on command and path", (done) ->
    @router.subscribe "/message", (next) ->
      assert.fail()
      
    @router.send "/message", (next) ->
      @state.ok = true
      next()
    
    @router.use (next) ->
      assert @state.ok
      next()
      
    context =
      command: "SEND"
      headers: { "destination": "/message" }
      state: {}
    
    @router.dispatch(context, done)

  it "should mount routers", (done) ->
    subrouter = new Router()
    subrouter.use (next) ->
      @ok = true
      next()
    
    @router.use subrouter
    
    @router.use (next) ->
      assert @ok
      next()
    
    @router.dispatch({}, done)

