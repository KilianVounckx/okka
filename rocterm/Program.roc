interface Program
    exposes [
        Program,
        ProgramWithTasks,
        run,
        runWithTasks,
    ]
    imports [
        cli.Stdin.{ bytes },
        cli.Stdout.{ write },
        cli.Task.{ Task },
        cli.Tty.{ enableRawMode, disableRawMode },
        Clear.{ all },
        Cursor.{ goto },
        Event.{ Event, fromBytes },
    ]

Program world : {
    init : {} -> world,
    update : world, Event -> [Continue world, Exit],
    display : world -> Str,
}

ProgramWithTasks world err : {
    init : {} -> Task world err,
    update : world, Event -> Task [Continue world, Exit] err,
    display : world -> Task Str err,
}

run : Program * -> Task {} *
run = \{ init, update, display } ->
    runWithTasks {
        init: \world -> Task.ok (init world),
        update: \world, event -> Task.ok (update world event),
        display: \world -> Task.ok (display world),
    }

runWithTasks : ProgramWithTasks * err -> Task {} err
runWithTasks = \{ init, update, display } ->
    {} <- enableRawMode |> Task.await

    initialWorld <- init {} |> Task.await
    {} <-
        Task.loop initialWorld \world ->
            rendered <- display world |> Task.await
            {} <- rendered |> write |> Task.await
            eventBytes <- bytes |> Task.await
            updatedWorld <- update world (fromBytes eventBytes) |> Task.await
            Task.ok
                (when updatedWorld is
                    Continue newWorld -> Step newWorld
                    Exit -> Done {})
        |> Task.await

    {} <- write (Str.joinWith [all, goto { row: 1, column: 1 }] "") |> Task.await
    {} <- disableRawMode |> Task.await

    Task.ok {}
