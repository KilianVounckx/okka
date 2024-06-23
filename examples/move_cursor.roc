app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.11.0/SY4WWMhWQ9NvQgvIthcv15AUeA7rAIJHAHgiaSHGhdY.tar.br",
    okka: "../package/main.roc",
}

import cli.Stdin
import cli.Stdout
import cli.Task exposing [Task]
import cli.Tty

import okka.Cursor
import okka.Event exposing [Event]

main : Task {} _
main =
    Tty.enableRawMode!
    size = getWindowSize!
    Task.loop! (init size) \model ->
        Stdout.write! (render model)
        input = Stdin.bytes!
        maybeEvent = Event.fromBytes input
        when maybeEvent is
            Ok event ->
                when update model event is
                    Ok newModel ->
                        Task.ok (Step newModel)

                    Err Quit ->
                        Task.ok (Done {})

            Err _ ->
                Task.ok (Step model)
    Tty.disableRawMode!

Model : {
    rows : U16,
    columns : U16,
    x : U16,
    y : U16,
}

init : { rows : U16, columns : U16 } -> Model
init = \{ rows, columns } -> {
    rows,
    columns,
    x: 0,
    y: 0,
}

update : Model, Event -> Result Model [Quit]
update = \model, event ->
    when event is
        Key Esc | Key (Char 'q') ->
            Err Quit

        Key Left | Key (Char 'h') ->
            Ok { model & x: Num.subSaturated model.x 1 }

        Key Right | Key (Char 'l') ->
            Ok { model & x: Num.min (model.x + 1) (model.columns - 1) }

        Key Up | Key (Char 'k') ->
            Ok { model & y: Num.subSaturated model.y 1 }

        Key Down | Key (Char 'j') ->
            Ok { model & y: Num.min (model.y + 1) (model.rows - 1) }

        _ ->
            Ok model

render : Model -> Str
render = \model ->
    Cursor.goto { row: model.y, column: model.x }

getWindowSize : Task { rows : U16, columns : U16 } _
getWindowSize =
    Stdout.write! "\u(1b)[999C\u(1b)[999B"
    { row, column } = getCursorPosition!
    Task.ok { rows: row, columns: column }

getCursorPosition : Task { row : U16, column : U16 } _
getCursorPosition =
    Stdout.write! "\u(1b)[6n\r\n"
    buf =
        Task.loop! [] \acc ->
            when Stdin.bytes! is
                [.. as bytes, 'R'] -> Task.ok (Done (List.concat bytes acc))
                bytes -> Task.ok (Step (List.concat acc bytes))
    when buf is
        [0x1b, '[', .. as rest] ->
            when List.splitFirst rest ';' is
                Ok { before, after } ->
                    maybeRow =
                        before
                        |> Str.fromUtf8
                        |> Result.try Str.toU16
                    maybeColumn =
                        after
                        |> Str.fromUtf8
                        |> Result.try Str.toU16
                    when (maybeRow, maybeColumn) is
                        (Ok row, Ok column) -> Task.ok { row, column }
                        other -> crash "could not get cursor position 1 $(Inspect.toStr other)"

                Err err -> crash "could not get cursor position 2 $(Inspect.toStr err)"

        other -> crash "could not get cursor position 3 $(Inspect.toStr other)"
