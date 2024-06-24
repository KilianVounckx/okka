app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.11.0/SY4WWMhWQ9NvQgvIthcv15AUeA7rAIJHAHgiaSHGhdY.tar.br",
    okka: "https://github.com/KilianVounckx/okka/releases/download/0.1.0/HI2Em-RnNzEl7Tlgs1Zzrp0feGMPwNvTSpTj1YrqSNY.tar.br",
}

import cli.Stdin
import cli.Stdout
import cli.Task exposing [Task]
import cli.Tty

import okka.Style exposing [Color]
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
    color : [Color Color, Erase],
    clear : Bool,
    x : U16,
    y : U16,
}

init : { rows : U16, columns : U16 } -> Model
init = \{ rows, columns } -> {
    rows,
    columns,
    brush: Up,
    color: Color Black,
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
            Ok { model1 & y: Num.min (model1.y + 1) (model1.rows - 3) }

        Key (Char ' ') ->
            Ok (toggleBrush model1)

        Key (Char 'E') | Key (Char 'e') -> Ok { model1 & color: Erase }
        Key (Char '1') -> Ok { model1 & color: Color Black }
        Key (Char '2') -> Ok { model1 & color: Color Red }
        Key (Char '3') -> Ok { model1 & color: Color Green }
        Key (Char '4') -> Ok { model1 & color: Color Yellow }
        Key (Char '5') -> Ok { model1 & color: Color Blue }
        Key (Char '6') -> Ok { model1 & color: Color Magenta }
        Key (Char '7') -> Ok { model1 & color: Color Cyan }
        Key (Char '8') -> Ok { model1 & color: Color White }
        Key Delete ->
            Ok ({ model1 & clear: Bool.true })

        _ ->
            Ok model1

toggleBrush : Model -> Model
toggleBrush = \model ->
    when model.brush is
        Up -> { model & brush: Down }
        Down -> { model & brush: Up }

render : Model -> Str
render = \model ->
    if model.clear then
        Str.joinWith [Clear.all, renderHelp model] ""
    else
        when (model.brush, model.color) is
            (Down, Color color) ->
                Str.joinWith
                    [
                        renderHelp model,
                        Cursor.hide,
                        Cursor.goto { row: model.y + 2, column: model.x },
                        Style.style [Background color],
                        " ",
                        Style.style [Background Default],
                    ]
                    ""

            (Down, Erase) ->
                Str.joinWith
                    [
                        renderHelp model,
                        Cursor.show,
                        Cursor.goto { row: model.y + 2, column: model.x },
                        Style.style [Background Default],
                        " ",
                    ]
                    ""

            (Up, _) ->
                Str.joinWith
                    [
                        renderHelp model,
                        Cursor.hide,
                        Cursor.goto { row: model.y + 2, column: model.x },
                        Cursor.show,
                    ]
                    ""

renderHelp : Model -> Str
renderHelp = \model ->
    Str.joinWith
        [
            Cursor.hide,
            # Tool
            Cursor.goto { row: 0, column: 0 },
            "Colors ",
            Style.style [Background Black],
            "   ",
            Style.style [Background Red],
            "   ",
            Style.style [Background Green],
            "   ",
            Style.style [Background Yellow],
            "   ",
            Style.style [Background Blue],
            "   ",
            Style.style [Background Magenta],
            "   ",
            Style.style [Background Cyan],
            "   ",
            Style.style [Background White],
            "   ",
            Style.style [Reset],
            "  Eraser",
            renderBrushHelp model,
            "  Clear",
            "  Quit",
            # Button
            Cursor.goto { row: 1, column: 0 },
            "       ",
            renderColorPickerNumbers model,
            "      SPACE    ",
            "   DEL ",
            "   ESC",
        ]
        ""

renderBrushHelp : Model -> Str
renderBrushHelp = \model ->
    when model.brush is
        Up ->
            Str.joinWith
                [
                    "  Brush ",
                    Style.style [Bold On],
                    "up",
                    Style.style [Bold Off],
                    "/down",
                ]
                ""

        Down ->
            Str.joinWith
                [
                    "  Brush up/",
                    Style.style [Bold On],
                    "down",
                    Style.style [Bold Off],
                ]
                ""

renderColorPickerNumbers : Model -> Str
renderColorPickerNumbers = \model ->
    when model.color is
        Erase ->
            Str.joinWith
                [
                    " 1  2  3  4  5  6  7  8 ",
                    "     ",
                    Style.style [Background Red, Bold On],
                    "E",
                    Style.style [Reset],
                    "  ",
                ]
                ""

        Color Black ->
            Str.joinWith
                [
                    Style.style [Foreground Black, Bold On],
                    " 1 ",
                    Style.style [Reset],
                    " 2  3  4  5  6  7  8 ",
                    "     E  ",
                ]
                ""

        Color Red ->
            Str.joinWith
                [
                    " 1 ",
                    Style.style [Foreground Red, Bold On],
                    " 2 ",
                    Style.style [Reset],
                    " 3  4  5  6  7  8 ",
                    "     E  ",
                ]
                ""

        Color Green ->
            Str.joinWith
                [
                    " 1  2 ",
                    Style.style [Foreground Green, Bold On],
                    " 3 ",
                    Style.style [Reset],
                    " 4  5  6  7  8 ",
                    "     E  ",
                ]
                ""

        Color Yellow ->
            Str.joinWith
                [
                    " 1  2  3 ",
                    Style.style [Foreground Yellow, Bold On],
                    " 4 ",
                    Style.style [Reset],
                    " 5  6  7  8 ",
                    "     E  ",
                ]
                ""

        Color Blue ->
            Str.joinWith
                [
                    " 1  2  3  4 ",
                    Style.style [Foreground Blue, Bold On],
                    " 5 ",
                    Style.style [Reset],
                    " 6  7  8 ",
                    "     E  ",
                ]
                ""

        Color Magenta ->
            Str.joinWith
                [
                    " 1  2  3  4  5 ",
                    Style.style [Foreground Magenta, Bold On],
                    " 6 ",
                    Style.style [Reset],
                    " 7  8 ",
                    "     E  ",
                ]
                ""

        Color Cyan ->
            Str.joinWith
                [
                    " 1  2  3  4  5  6 ",
                    Style.style [Foreground Cyan, Bold On],
                    " 7 ",
                    Style.style [Reset],
                    " 8 ",
                    "     E  ",
                ]
                ""

        Color White ->
            Str.joinWith
                [
                    " 1  2  3  4  5  6  7 ",
                    Style.style [Foreground White, Bold On],
                    " 8 ",
                    Style.style [Reset],
                    "     E  ",
                ]
                ""

        Color color -> crash "unpickable color: $(Inspect.toStr color)"

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
