app "okka"
    packages {
        cli: "../basic-cli/src/main.roc",
        rocterm: "../rocterm/main.roc",
    }
    imports [
        cli.Task.{ Task },
        rocterm.Clear,
        rocterm.Cursor,
        rocterm.Event.{ Event },
        rocterm.Program,
    ]
    provides [main] to cli

main : Task {} I32
main = Program.run {
    init: initialWorld,
    update,
    display,
}

World : {
    toPrint : Str,
}

initialWorld : {} -> World
initialWorld = \{} -> {
    toPrint: "Initial",
}

update : World, Event -> [Continue World, Exit]
update = \world, event ->
    when event is
        Key key ->
            when key is
                Ctrl 'q' -> Exit
                F f ->
                    Continue
                        { world &
                            toPrint: "F: " |> Str.concat (Num.toStr f),
                        }

                Return ->
                    Continue
                        { world &
                            toPrint: "enter",
                        }

                Tab ->
                    Continue
                        { world &
                            toPrint: "tab",
                        }

                Char c ->
                    Continue
                        { world &
                            toPrint: Str.fromUtf8 [c] |> Result.withDefault "No utf8 char",
                        }

                Ctrl c ->
                    Continue
                        { world &
                            toPrint: "Ctrl: " |> Str.appendScalar (Num.intCast c) |> Result.withDefault "No utf8 ctrl",
                        }

                Alt c ->
                    Continue
                        { world &
                            toPrint: "Alt: " |> Str.appendScalar (Num.intCast c) |> Result.withDefault "No utf8 ctrl",
                        }

                Left ->
                    Continue
                        { world &
                            toPrint: "left",
                        }

                Right ->
                    Continue
                        { world &
                            toPrint: "right",
                        }

                Up ->
                    Continue
                        { world &
                            toPrint: "up",
                        }

                Down ->
                    Continue
                        { world &
                            toPrint: "down",
                        }

                Home ->
                    Continue
                        { world &
                            toPrint: "home",
                        }

                End ->
                    Continue
                        { world &
                            toPrint: "end",
                        }

                PageUp ->
                    Continue
                        { world &
                            toPrint: "pageup",
                        }

                PageDown ->
                    Continue
                        { world &
                            toPrint: "pagedown",
                        }

                BackTab ->
                    Continue
                        { world &
                            toPrint: "backtab",
                        }

                Esc ->
                    Continue
                        { world &
                            toPrint: "escape",
                        }

                Backspace ->
                    Continue
                        { world &
                            toPrint: "backspace",
                        }

                Delete ->
                    Continue
                        { world &
                            toPrint: "delete",
                        }

                Insert ->
                    Continue
                        { world &
                            toPrint: "insert",
                        }

                Null ->
                    Continue
                        { world &
                            toPrint: "null",
                        }

        Unsupported _ ->
            Continue
                { world &
                    toPrint: "unsupported",
                }

display : World -> Str
display = \{ toPrint } ->
    Str.joinWith
        [
            Clear.all,
            Cursor.goto { row: 1, column: 1 },
            toPrint,
            Cursor.goto { row: 3, column: 3 },
        ]
        ""
