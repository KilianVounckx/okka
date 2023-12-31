interface Row
    exposes [
        Row,
        fromChars,
        fromStr,
        cursorXToRenderX,
        insertChar,
        deleteChar,
        appendChars,
    ]
    imports []

Row : {
    chars : List U8,
    render : List U8,
}

fromStr : Str -> Row
fromStr = \str ->
    str
    |> Str.toUtf8
    |> fromChars

fromChars : List U8 -> Row
fromChars = \chars ->
    row = {
        chars,
        render: [],
    }
    update row

update : Row -> Row
update = \row ->
    tabs = List.countIf row.chars \c -> c == '\t'
    render =
        List.walk row.chars (List.withCapacity (List.len row.chars + tabs * 7)) \state, char ->
            if char == '\t' then
                state1 = List.append state ' '
                lenMod = List.len state1 % tabstop
                if lenMod == 0 then
                    state1
                else
                    List.concat state1 (List.repeat ' ' (tabstop - lenMod))
            else
                List.append state char
    { row & render }

appendChars : Row, List U8 -> Row
appendChars = \row, chars ->
    newChars = List.concat row.chars chars
    update { row & chars: newChars }

deleteChar : Row, Nat -> Row
deleteChar = \row, index ->
    before = List.takeFirst row.chars index
    after = List.drop row.chars (index + 1)
    chars = List.concat before after
    update { row & chars }

insertChar : Row, Nat, U8 -> Row
insertChar = \row, index, char ->
    before = List.takeFirst row.chars index
    after = List.drop row.chars index
    chars = before |> List.append char |> List.concat after
    update { row & chars }

cursorXToRenderX : Row, U16 -> U16
cursorXToRenderX = \row, cursorX ->
    row.chars
    |> List.sublist { start: 0, len: Num.intCast cursorX }
    |> List.walk 0 \renderX, char ->
        if char == '\t' then
            renderX + (tabstop - 1) - (renderX % tabstop) + 1
        else
            renderX + 1

tabstop = 8
