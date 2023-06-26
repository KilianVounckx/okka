interface Editor
    exposes [
        Editor,
        init,
        update,
        display,
    ]
    imports [
        cli.Arg.{ list },
        cli.File.{ ReadErr, readUtf8, writeUtf8 },
        cli.Path.{ Path, fromStr },
        cli.Task.{ Task },
        rocterm.Clear.{ untilNewLine },
        rocterm.Cursor.{ goto, hide, show },
        rocterm.Event.{ Event },
        rocterm.Style.{ invert, reset },
        Row.{ Row },
    ]

Editor : {
    screenRows : U16,
    screenColumns : U16,
    rowOffset : U16,
    columnOffset : U16,
    cursorX : U16,
    cursorY : U16,
    renderX : U16,
    rows : List Row,
    filename : [Filename Str, NoFilename],
    statusMessage : Str,
    dirty : Bool,
    quitTimes : U8,
}

init : {} -> Task Editor [FileReadErr Path ReadErr, FileReadUtf8Err Path _]
init = \{} ->
    args <- list |> Task.await
    (rows, filename) <-
        (
            when args is
                [_, filename] ->
                    rows <- filename |> openFile |> Task.map
                    (rows, Filename filename)

                _ -> Task.ok ([], NoFilename)
        )
        |> Task.await

    Task.ok {
        screenRows: 20 - 2,
        screenColumns: 50,
        rowOffset: 0,
        columnOffset: 0,
        cursorX: 0,
        cursorY: 0,
        renderX: 0,
        rows,
        filename,
        statusMessage: "HELP: Ctrl-Q = quit | Ctrl-S = save",
        dirty: Bool.false,
        quitTimes,
    }

openFile : Str -> Task (List Row) [FileReadErr Path ReadErr, FileReadUtf8Err Path _]
openFile = \filename ->
    contents <- filename |> fromStr |> readUtf8 |> Task.await
    contents
    |> Str.split "\n"
    |> List.map Row.fromStr
    |> Task.ok

save : Editor -> Task Editor *
save = \editor ->
    when editor.filename is
        NoFilename -> Task.ok editor
        Filename filename ->
            contents = rowsToStr editor
            result <- filename |> fromStr |> writeUtf8 contents |> Task.attempt
            when result is
                Ok {} ->
                    length = Num.toStr (Str.countUtf8Bytes contents)
                    Task.ok { editor & statusMessage: "\(length) bytes written to disk", dirty: Bool.false }
                Err (FileWriteErr _ _) ->
                    Task.ok { editor & statusMessage: "Can't save! I/O error" }

rowsToStr : Editor -> Str
rowsToStr = \editor ->
    editor.rows
    |> List.map \row ->
        when Str.fromUtf8 row.chars is
            Ok line -> line
            Err _ -> crash "unreachable (in rowsToStr fromUtf8)"
    |> Str.joinWith "\n"
    |> Str.concat "\n"

update : Editor, Event -> Task [Continue Editor, Exit] *
update = \editor, event ->
    resetQuitTimes : Editor -> Editor
    resetQuitTimes = \ed ->
        { ed & quitTimes }
    when event is
        Key key ->
            when key is
                Ctrl 'q' ->
                    if editor.quitTimes == 0 || !editor.dirty then
                        Task.ok Exit
                    else
                        quitTimesStr = Num.toStr editor.quitTimes
                        statusMessage = "WARNING!!! File has unsaved changes. Press Ctrl-Q \(quitTimesStr) more times to quit."
                        Task.ok (Continue (scroll { editor & statusMessage, quitTimes: editor.quitTimes - 1 }))
                Ctrl 's' -> save editor |> Task.map Continue

                Left -> Task.ok (Continue (resetQuitTimes (scroll  (moveCursor editor Left))))
                Right -> Task.ok (Continue (resetQuitTimes (scroll  (moveCursor editor Right))))
                Up -> Task.ok (Continue (resetQuitTimes (scroll  (moveCursor editor Up))))
                Down -> Task.ok (Continue (resetQuitTimes (scroll  (moveCursor editor Down))))
                PageUp | PageDown ->
                    editor1 =
                        if key == PageUp then
                            { editor & cursorY: editor.rowOffset + 0 } # for some reason without `+ 0` doesn't work
                        else
                            { editor & cursorY: Num.min (Num.intCast (List.len editor.rows)) (editor.rowOffset + editor.screenRows - 1) }

                    times = editor1.screenRows
                    direction = if key == PageUp then Up else Down
                    Task.ok (Continue (resetQuitTimes (scroll  (moveCursorMany editor1 direction times))))

                Home -> Task.ok (Continue (resetQuitTimes (scroll  { editor & cursorX: 0 })))
                End ->
                    Task.ok (Continue
                        (resetQuitTimes (
                        
                            scroll
                                (
                                    when List.get editor.rows (Num.intCast editor.cursorY) is
                                        Ok row -> { editor & cursorX: Num.intCast (List.len row.chars) }
                                        Err _ -> editor
                                )
                        )))

                Char char -> Task.ok (Continue (resetQuitTimes (scroll (insertChar editor char))))
                Tab -> Task.ok (Continue (resetQuitTimes (scroll (insertChar editor '\t'))))

                Delete ->
                    editor |> moveCursor Right |> deleteChar |> scroll |> resetQuitTimes |> Continue |> Task.ok
                Backspace | Ctrl 'h' ->
                    editor |> deleteChar |> scroll |> resetQuitTimes |> Continue |> Task.ok
                Return ->
                    editor |> insertNewLine |> scroll |> resetQuitTimes |> Continue |> Task.ok

                Ctrl 'l' -> Task.ok (Continue  editor)

                _ -> Task.ok (Continue  editor)

        _ -> Task.ok (Continue editor)

deleteRow : Editor, Nat -> Editor
deleteRow = \editor, index ->
    before = List.takeFirst editor.rows index
    after = List.drop editor.rows (index + 1)
    newRows = List.concat before after
    { editor & rows: newRows, dirty: Bool.true }

insertRow : Editor, Nat, List U8 -> Editor
insertRow = \editor, index, chars ->
    before = List.takeFirst editor.rows index
    after = List.drop editor.rows index
    rows = before |> List.append (Row.fromChars chars) |> List.concat after
    { editor & rows, dirty: Bool.true }

insertNewLine : Editor -> Editor
insertNewLine = \editor ->
    (if editor.cursorX == 0 then
        insertRow editor (Num.intCast editor.cursorY) []
    else
        when List.get editor.rows (Num.intCast editor.cursorY) is
            Ok row ->
                before = List.takeFirst row.chars (Num.intCast editor.cursorX)
                after = List.drop row.chars (Num.intCast editor.cursorX)
                newRow = Row.fromChars before
                newRows = List.set editor.rows (Num.intCast editor.cursorY) newRow
                { editor & rows: newRows }
                |> insertRow (Num.intCast editor.cursorY + 1) after
            Err _ -> crash "unreachable (in insertNewLine)")
    |> \ed -> { ed & cursorY: ed.cursorY + 1, cursorX: 0 }

deleteChar : Editor -> Editor
deleteChar = \editor ->
    when List.get editor.rows (Num.intCast editor.cursorY) is
        Ok row ->
            if editor.cursorX > 0 then
                newRow = Row.deleteChar row (Num.intCast editor.cursorX - 1)
                newRows = List.set editor.rows (Num.intCast editor.cursorY) newRow
                { editor & rows: newRows, cursorX: editor.cursorX - 1, dirty: Bool.true }
            else if editor.cursorY > 0 then
                when List.get editor.rows (Num.intCast editor.cursorY - 1) is
                    Ok rowBelow ->
                        cursorX = Num.intCast (List.len rowBelow.chars)
                        newRowBelow = Row.appendChars rowBelow row.chars
                        newRows = List.set editor.rows (Num.intCast editor.cursorY - 1) newRowBelow
                        { editor & cursorX, cursorY: editor.cursorY - 1, rows: newRows, dirty: Bool.true } |> deleteRow (Num.intCast editor.cursorY)
                    Err _ -> crash "unreachable (in deleteChar rowBelow)"
            else
                editor
        Err _ -> editor

insertChar : Editor, U8 -> Editor
insertChar = \editor, char ->
    appendIfNeeded : Editor -> Editor
    appendIfNeeded = \ed ->
        if Num.intCast ed.cursorY == List.len (ed.rows) then
            insertRow editor (List.len editor.rows) []
        else
            ed

    addChar : Editor -> Editor
    addChar = \ed ->
        rows = ed.rows
        newRows = List.update rows (Num.intCast ed.cursorY) (\row -> Row.insertChar row (Num.intCast ed.cursorX) char)
        { ed & rows: newRows }

    shiftCursor : Editor -> Editor
    shiftCursor = \ed ->
        { ed & cursorX: ed.cursorX + 1 }

    makeDirty : Editor -> Editor
    makeDirty = \ed ->
        { ed & dirty: Bool.true }

    editor |> appendIfNeeded |> addChar |> shiftCursor |> makeDirty

scroll : Editor -> Editor
scroll = \editor ->
    setRenderX : Editor -> Editor
    setRenderX = \ed ->
        when List.get ed.rows (Num.intCast ed.cursorY) is
            Ok row -> { ed & renderX: Row.cursorXToRenderX row ed.cursorX }
            Err _ -> { ed & renderX: 0 }
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
        if ed.renderX < ed.columnOffset then
            { ed & columnOffset: ed.renderX + 0 } # for some reason without `+ 0` doesn't work
        else
            ed
    scrollRight : Editor -> Editor
    scrollRight = \ed ->
        if ed.renderX >= ed.columnOffset + ed.screenColumns then
            { ed & columnOffset: ed.renderX - ed.screenColumns + 1 }
        else
            ed
    editor |> setRenderX |> scrollUp |> scrollDown |> scrollLeft |> scrollRight

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
                if ed.cursorY < Num.intCast (List.len ed.rows) then
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
        drawStatusBar editor,
        drawMessageBar editor,
        goto { row: editor.cursorY - editor.rowOffset + 1, column: editor.renderX - editor.columnOffset + 1 },
        show,
    ]
    |> Str.joinWith ""
    |> Task.ok

drawRows : Editor -> Str
drawRows = \editor ->
    List.range { start: At 0, end: Before editor.screenRows }
    |> List.map \y ->
        fileRow = y + editor.rowOffset
        [
            (
                if Num.intCast fileRow >= List.len editor.rows then
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
                    when row.render |> List.sublist { start: Num.intCast editor.columnOffset, len: Num.intCast editor.screenColumns } |> Str.fromUtf8 is
                        Ok s -> s
                        Err _ -> crash "unreachable (in drawRows row render)"
            ),
            untilNewLine,
            "\r\n",
        ]
        |> Str.joinWith ""
    |> Str.joinWith ""

drawStatusBar : Editor -> Str
drawStatusBar = \editor ->
    [
        invert,
        (
            leftStatus =
                filename = when editor.filename is
                    Filename name -> name
                    NoFilename -> "[No Name]"
                numLines = Num.toStr (List.len editor.rows)
                modified = if editor.dirty then "(modified)" else ""
                fullStatus = "\(filename) - \(numLines) lines \(modified)"
                when fullStatus |> Str.toUtf8 |> List.takeFirst (Num.intCast editor.screenColumns) |> Str.fromUtf8 is
                    Ok s -> s
                    Err _ -> crash "unreachable (in drawRows row render)"
            rightStatus =
                line = Num.toStr editor.cursorY
                numLines = Num.toStr (List.len editor.rows)
                "\(line)/\(numLines)"
            if Str.countUtf8Bytes leftStatus + Str.countUtf8Bytes rightStatus >= Num.intCast editor.screenColumns then
                padding = Str.repeat " " (Num.intCast editor.screenColumns - Str.countUtf8Bytes leftStatus)
                "\(leftStatus)\(padding)"
            else
                padding = Str.repeat " " (Num.intCast editor.screenColumns - Str.countUtf8Bytes leftStatus - Str.countUtf8Bytes rightStatus)
                "\(leftStatus)\(padding)\(rightStatus)"
        ),
        reset,
        "\r\n",
    ]
    |> Str.joinWith ""

drawMessageBar : Editor -> Str
drawMessageBar = \editor ->
    [
        untilNewLine,
        (when editor.statusMessage |> Str.toUtf8 |> List.takeFirst (Num.intCast editor.screenColumns) |> Str.fromUtf8 is
            Ok s -> s
            Err _ -> crash "unreachable (in drawRows row render)"),
    ]
    |> Str.joinWith ""

quitTimes = 3
