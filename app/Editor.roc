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
    rowOffset : U16,
    columnOffset : U16,
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
        rowOffset: 0,
        columnOffset: 0,
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
                Left -> Continue (scroll (moveCursor editor Left))
                Right -> Continue (scroll (moveCursor editor Right))
                Up -> Continue (scroll (moveCursor editor Up))
                Down -> Continue (scroll (moveCursor editor Down))
                PageUp | PageDown ->
                    times = editor.screenRows
                    direction = if key == PageUp then Up else Down
                    Continue (scroll (moveCursorMany editor direction times))
                Home -> Continue (scroll { editor & cursorX: 0 })
                End -> Continue (scroll { editor & cursorX: editor.screenColumns - 1 })
                _ -> Continue editor
        _ -> Continue (scroll editor)
)

scroll : Editor -> Editor
scroll = \editor ->
    scrollUp : Editor -> Editor
    scrollUp = \ed ->
        if ed.cursorY < ed.rowOffset then
            { ed & rowOffset: ed.cursorY }
        else
            ed
    scrollDown : Editor -> Editor
    scrollDown = \ed ->
        if ed.cursorY >= ed.rowOffset + ed.screenRows then
            { ed & rowOffset: ed.cursorY - ed.screenRows + 1 }
        else
            ed
    scrollLeft : Editor -> Editor
    scrollLeft = \ed ->
        if ed.cursorX < ed.columnOffset then
            { ed & columnOffset: ed.cursorX + 0 } # for some reason without `+ 0` doesn't work
        else
            ed
    scrollRight : Editor -> Editor
    scrollRight = \ed ->
        if ed.cursorX >= ed.columnOffset + ed.screenColumns then
            { ed & columnOffset: ed.cursorX - ed.screenColumns + 1 }
        else
            ed
    editor |> scrollUp |> scrollDown |> scrollLeft |> scrollRight

moveCursorMany : Editor, [Left, Right, Up, Down], U16 -> Editor
moveCursorMany = \editor, direction, times ->
    if times == 0 then
        editor
    else
        moveCursorMany (moveCursor editor direction) direction (times - 1)

moveCursor : Editor, [Left, Right, Up, Down] -> Editor
moveCursor = \editor, direction ->
    move : Editor -> Editor
    move = \ed ->
        when direction is
            Left ->
                if ed.cursorX > 0 then
                    newX = ed.cursorX - 1
                    { ed & cursorX: newX }
                else if ed.cursorY > 0 then
                    newY = ed.cursorY - 1
                    row =
                        when List.get editor.rows (Num.intCast newY) is
                            Ok r -> r
                            Err _ -> crash "unreachable (in moveCursor left at start of line)"
                    { ed & cursorY: newY, cursorX: Num.intCast (List.len row.chars) }
                else
                    ed
            Right ->
                when List.get ed.rows (Num.intCast ed.cursorY) is
                    Ok row ->
                        if Num.intCast ed.cursorX < List.len row.chars then
                            newX = ed.cursorX + 1
                            { ed & cursorX: newX }
                        else
                            { ed & cursorY: ed.cursorY + 1, cursorX: 0 }
                    _ ->
                        ed
            Up ->
                if ed.cursorY > 0 then
                    { ed & cursorY: ed.cursorY - 1 }
                else
                    ed
            Down ->
                if ed.cursorY < Num.intCast (List.len ed.rows) - 1 then
                    { ed & cursorY: ed.cursorY + 1 }
                else
                    ed
    snap : Editor -> Editor
    snap = \ed ->
        length =
            when List.get ed.rows (Num.intCast ed.cursorY) is
                Ok row -> Num.intCast (List.len row.chars)
                Err _ -> 0
            if ed.cursorX > length then
                { ed & cursorX: length }
            else
                ed

    editor |> move |> snap

display : Editor -> Task Str *
display = \editor ->
    [
        hide,
        goto { row: 1, column: 1 },
        drawRows editor,
        goto { row: editor.cursorY - editor.rowOffset + 1, column: editor.cursorX - editor.columnOffset + 1 },
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
        fileRow = y + editor.rowOffset
        [
            (if Num.intCast fileRow >= List.len editor.rows then
                [
                    if List.isEmpty editor.rows && y == editor.screenRows // 3 then
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
                ]
                |> Str.joinWith ""
            else
                row =
                    when List.get editor.rows (Num.intCast fileRow) is
                        Ok r -> r
                        Err _ -> crash "unreachable (in drawRows row get)"
                when row.chars |> List.sublist { start: Num.intCast editor.columnOffset, len: Num.intCast editor.screenColumns } |> Str.fromUtf8 is
                    Ok s -> s
                    Err _ -> crash "unreachable (in drawRows row render)"),
            untilNewLine,
            if y < editor.screenRows - 1 then "\r\n" else "",
        ]
        |> Str.joinWith ""
    |> Str.joinWith ""
