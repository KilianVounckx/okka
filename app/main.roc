app "okka"
    packages {
        # cli: "https://github.com/roc-lang/basic-cli/releases/download/0.4.0/DI4lqn7LIZs8ZrCDUgLK-tHHpQmxGF1ZrlevRKq5LXk.tar.br",
        # cli: "https://github.com/roc-lang/basic-cli/releases/download/0.4.0/N2H7rEuSe0dl6MJunQsAF7spj23mqj9SBd5kgYVjVz8.tar.gz",
        cli: "../basic-cli/src/main.roc",
    }
    imports [
        cli.Stdin,
        cli.Stdout,
        cli.Task.{ Task },
        cli.Tty,
        Clear,
        Cursor,
        Key.{ Key },
    ]
    provides [main] to cli

main : Task {} I32
main =
    {} <- Tty.enableRawMode |> Task.await

    {} <-
        Task.loop (initialWorld {}) \world ->
            {} <- display world |> Stdout.write |> Task.await
            event <- Stdin.bytes |> Task.await
            Task.ok (update world (Key.fromBytes event))
        |> Task.await

    {} <- Tty.disableRawMode |> Task.await
    Task.ok {}

World : {
    toPrint : Str,
}

initialWorld : {} -> World
initialWorld = \{} ->
    {
        toPrint: "Initial",
    }

update : World, Key -> [Step World, Done {}]
update = \{}, key ->
    when key is
        Ctrl 'q' -> Done {}
        F f -> Step {
            toPrint: "F: " |> Str.concat (Num.toStr f),
        }
        Return -> Step {
            toPrint: "enter",
        }
        Tab -> Step {
            toPrint: "tab",
        }
        Char c -> Step {
            toPrint: Str.fromUtf8 [c] |> Result.withDefault "No utf8 char",
        }
        Ctrl c -> Step {
            toPrint: "Ctrl: " |> Str.appendScalar (Num.intCast c) |> Result.withDefault "No utf8 ctrl"
        }
        Alt c -> Step {
            toPrint: "Alt: " |> Str.appendScalar (Num.intCast c) |> Result.withDefault "No utf8 ctrl"
        }
        Left -> Step {
            toPrint: "left",
        }
        Right -> Step {
            toPrint: "right",
        }
        Up -> Step {
            toPrint: "up",
        }
        Down -> Step {
            toPrint: "down",
        }
        Home -> Step {
            toPrint: "home",
        }
        End -> Step {
            toPrint: "end",
        }
        PageUp -> Step {
            toPrint: "pageup",
        }
        PageDown -> Step {
            toPrint: "pagedown",
        }
        BackTab -> Step {
            toPrint: "backtab",
        }
        Esc -> Step {
            toPrint: "escape",
        }
        _ -> Step {
            toPrint: "No char",
        }

display : World -> Str
display = \{ toPrint } ->
    Str.joinWith [Clear.all, Cursor.goto 1 1, toPrint] ""
