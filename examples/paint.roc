app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.11.0/SY4WWMhWQ9NvQgvIthcv15AUeA7rAIJHAHgiaSHGhdY.tar.br",
    okka: "../package/main.roc",
}

import cli.Stdin
import cli.Stdout
import cli.Task exposing [Task]
import cli.Tty

import okka.Color exposing [Color]
import okka.Clear
import okka.Cursor
import okka.Event exposing [Event]

main : Task {} _
main =
    Tty.enableRawMode!
    Stdout.write! Clear.all
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
    Stdout.write! Cursor.show
    Tty.disableRawMode!

Model : {
    rows : U16,
    columns : U16,
    brush : [Up, Down],
    color : Color,
    clear : Bool,
    x : U16,
    y : U16,
}

init : { rows : U16, columns : U16 } -> Model
init = \{ rows, columns } -> {
    rows,
    columns,
    brush: Down,
    color: Red,
    clear: Bool.false,
    x: 0,
    y: 0,
}

update : Model, Event -> Result Model [Quit]
update = \model0, event ->
    model1 = { model0 & clear: Bool.false }
    when event is
        Key Esc | Key (Char 'q') ->
            Err Quit

        Key Left | Key (Char 'h') ->
            Ok { model1 & x: Num.subSaturated model1.x 1 }

        Key Right | Key (Char 'l') ->
            Ok { model1 & x: Num.min (model1.x + 1) (model1.columns - 1) }

        Key Up | Key (Char 'k') ->
            Ok { model1 & y: Num.subSaturated model1.y 1 }

        Key Down | Key (Char 'j') ->
            Ok { model1 & y: Num.min (model1.y + 1) (model1.rows - 1) }

        Key (Char ' ') ->
            Ok (toggleBrush model1)

        Key (Char 'c') ->
            Ok (toggleColor model1)

        Key Delete ->
            Ok ({ model1 & clear: Bool.true })

        _ ->
            Ok model1

toggleColor : Model -> Model
toggleColor = \model ->
    when model.color is
        Red -> { model & color: Blue }
        _ -> { model & color: Red }

toggleBrush : Model -> Model
toggleBrush = \model ->
    when model.brush is
        Up -> { model & brush: Down }
        Down -> { model & brush: Up }

render : Model -> Str
render = \model ->
    if model.clear then
        Clear.all
    else
        when model.brush is
            Down ->
                Str.joinWith
                    [
                        Cursor.hide,
                        Cursor.goto { row: model.y, column: model.x },
                        Color.background model.color,
                        " ",
                        Color.background Reset,
                    ]
                    ""

            Up ->
                Str.joinWith
                    [
                        Cursor.hide,
                        Cursor.goto { row: model.y, column: model.x },
                        Cursor.show,
                    ]
                    ""

# https://viewsourcecode.org/snaptoken/kilo/03.rawInputAndOutput.html#window-size-the-hard-way
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
