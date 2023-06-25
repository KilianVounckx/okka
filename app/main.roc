app "okka"
    packages {
        cli: "../basic-cli/src/main.roc",
        rocterm: "../rocterm/main.roc",
    }
    imports [
        cli.Stderr,
        cli.Task.{ Task },
        rocterm.Program,
        Editor.{ init, update, display },
    ]
    provides [main] to cli

main : Task {} I32
main =
    task = Program.runWithTasks {
        init,
        update,
        display,
    }
    Task.attempt task \result ->
        when result is
            Ok {} -> Task.ok {}
            Err _ ->
                {} <- Stderr.line "Could not read file" |> Task.await
                Task.err 1
