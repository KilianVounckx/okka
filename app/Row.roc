interface Row
    exposes [
        Row,
        fromStr,
        cursorXToRenderX,
    ]
    imports []

Row : {
    chars : List U8,
    render : List U8,
}

fromStr : Str -> Row
fromStr = \str ->
    chars = Str.toUtf8 str
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
