interface Editor
    exposes [
        Editor,
        init,
        update,
        display,
    ]
    imports [
        cli.Arg.{ list },
        cli.File.{ ReadErr, readUtf8 },
        cli.Path.{ Path, fromStr },
        cli.Task.{ Task },
        rocterm.Clear.{ untilNewLine },
        rocterm.Cursor.{ goto, hide, show },
        rocterm.Event.{ Event },
    ]

Editor : {
    screenRows : U16,
    screenColumns : U16,
    cursorX : U16,
    cursorY : U16,
    rows: List Row,
    filename: [Filename Str, NoFilename],
}

Row : {
    chars: List U8,
}

init : {} -> Task Editor [FileReadErr Path ReadErr, FileReadUtf8Err Path _]
init = \{} ->
    args <- list |> Task.await
    (rows, filename) <-
        (when args is
            [_, filename] ->
                rows <- filename |> openFile |> Task.map
                (rows, Filename filename)
            _ -> Task.ok ([], NoFilename)) |> Task.await

    Task.ok {
        screenRows: 20,
        screenColumns: 50,
        cursorX: 0,
        cursorY: 0,
        rows,
        filename,
    }

update : Editor, Event -> Task [Continue Editor, Exit] *
update = \editor, event -> Task.ok (
    when event is
        Key key ->
            when key is
                Ctrl 'q' -> Exit
                Left -> Continue (moveCursor editor Left)
                Right -> Continue (moveCursor editor Right)
                Up -> Continue (moveCursor editor Up)
                Down -> Continue (moveCursor editor Down)
                PageUp | PageDown ->
                    times = editor.screenRows
                    direction = if key == PageUp then Up else Down
                    Continue (moveCursorMany editor direction times)
                Home -> Continue { editor & cursorX: 0 }
                End -> Continue { editor & cursorX: editor.screenColumns - 1 }
                _ -> Continue editor
        _ -> Continue editor
)

moveCursorMany : Editor, [Left, Right, Up, Down], U16 -> Editor
moveCursorMany = \editor, direction, times ->
    if times == 0 then
        editor
    else
        moveCursorMany (moveCursor editor direction) direction (times - 1)

moveCursor : Editor, [Left, Right, Up, Down] -> Editor
moveCursor = \editor, direction ->
    when direction is
        Left ->
            if editor.cursorX > 0 then
                { editor & cursorX: editor.cursorX - 1 }
            else
                editor
        Right ->
            if editor.cursorX < editor.screenColumns - 1 then
                { editor & cursorX: editor.cursorX + 1 }
            else
                editor
        Up ->
            if editor.cursorY > 0 then
                { editor & cursorY: editor.cursorY - 1 }
            else
                editor
        Down ->
            if editor.cursorY < editor.screenRows - 1 then
                { editor & cursorY: editor.cursorY + 1 }
            else
                editor

display : Editor -> Task Str *
display = \editor ->
    [
        hide,
        goto { row: 1, column: 1 },
        drawRows editor,
        goto { row: editor.cursorY + 1, column: editor.cursorX + 1 },
        show,
    ]
    |> Str.joinWith ""
    |> Task.ok

openFile : Str -> Task (List Row) [FileReadErr Path ReadErr, FileReadUtf8Err Path _]
openFile = \filename ->
    contents <- filename |> fromStr |> readUtf8 |> Task.await
    contents
    |> Str.split "\n"
    |> List.map \line -> { chars: Str.toUtf8 line }
    |> Task.ok

drawRows : Editor -> Str
drawRows = \editor ->
    List.range { start: At 0, end: Before editor.screenRows }
    |> List.map \y ->
        [
            if y == editor.screenRows // 3 then
                fullWelcome = "Okka editor -- version 0.0.1"
                welcome =
                    when fullWelcome |> Str.toUtf8 |> List.takeFirst (Num.intCast editor.screenColumns) |> Str.fromUtf8 is
                        Ok s -> s
                        Err _ -> crash "unreachable (in drawRows welcome text)"
                padding = (Num.intCast editor.screenColumns - Str.countUtf8Bytes welcome) // 2
                header = if padding > 0 then "~" else " "
                [
                    header,
                    Str.repeat " " (padding - 1),
                    welcome,
                ]
                |> Str.joinWith ""
            else
                "~",
            untilNewLine,
            if y < editor.screenRows - 1 then "\r\n" else "",
        ]
        |> Str.joinWith ""
    |> Str.joinWith ""
