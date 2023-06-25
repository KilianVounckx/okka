interface Program
    exposes [
        Program,
        run,
    ]
    imports [
        cli.Stdin.{ bytes },
        cli.Stdout.{ write },
        cli.Task.{ Task },
        cli.Tty.{ enableRawMode, disableRawMode },
        Event.{ Event },
    ]

Program world : {
    init : {} -> world,
    update : world, Event -> [Continue world, Exit],
    display : world -> Str,
}

run : Program * -> Task {} I32
run = \{ init, update, display } ->
    {} <- enableRawMode |> Task.await

    {} <-
        Task.loop (init {}) \world ->
            {} <- display world |> write |> Task.await
            eventBytes <- bytes |> Task.await
            Task.ok
                (
                    when update world (Event.fromBytes eventBytes) is
                        Continue newWorld -> Step newWorld
                        Exit -> Done {}
                )
        |> Task.await

    {} <- disableRawMode |> Task.await
    Task.ok {}
