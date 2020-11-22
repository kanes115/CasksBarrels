# CasksBarrels

1. How would you test the functionality here?

Well, I structured code in a way that decouples the IO part from the pure logic. That makes it pretty easy to test room's logic separately from room manager  and websocket handler. This way we can have solid unit tests of `CasksBarrels.Room` module, then by mocking `CasksBarrels.Room` we could test how room manager proxies messages to and from this module. Finally, we could test the socket itself separately. That would be a base of the pyramid of testing. Then of course we could write integration tests and e2e tests with the use of some weboscket clients.

Eventually, when a project grows larger it would be good to move towards a more MVC oriented design and for example decouple `cast_message`1 and `dump_message/1` functions to a separate module and test them separately.

When it comes to equivalence classes, obviously it's worth to test how registering and kicking players behaves before and after the `@min_players` is reached, for functions like `get_current_player/1` it would be good to test both regular case as well as state in which there's noone left in the room, what happens if `apply_answer/3` is called for non-existent player, for answer outside of type (that could also be tested with dialyzed on type level). That would be also good to check casks barrel rules themselves for all possible cases (numbers that should be passed as `casks/barrels/casks&barrels` but were passed as integers, if the value is really the next value etc.). Of course there's much more than that, I'd be happy to dwelve on that during the interview if there are questions.

2. Withd regards to the architecture of the solution ...

Due to the current approach rules are modeled in module `CasksBarrels.Room` so it should be as easy as modyfing it, nothing more. If new rules require new ways of communication with the client, there's also some work needed in the websocket layer. If we wanted to support multiple rooms, we would need to have a manager of room managers probably, maybe identify rooms with their ws paths (`ws://localhost:4000/ws/id_here`). If we wanted to persist rooms between server restarts we would need to add persistence layer, probably Ecto. It would require to save state modeled by `CasksBarrels.Room` to be persisted. If we wanted to have some authorization, it would probably be best to start using phoenix and phoenix channels. As this is a very open question, I'm also happy to discuss any further variations with you face to face.
