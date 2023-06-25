interface Key
    exposes [
        Key,
        fromBytes,
    ]
    imports []

Key : [
    Backspace,
    Left,
    Right,
    Up,
    Down,
    Home,
    End,
    PageUp,
    PageDown,
    BackTab,
    Tab,
    Delete,
    Insert,
    F U8,
    Char U8,
    Alt U8,
    Ctrl U8,
    Null,
    Esc,
    Return,
]

fromBytes : List U8 -> Key
fromBytes = \event ->
    when event is
        [0x1b, '[', 'A'] -> Up
        [0x1b, '[', 'B'] -> Down
        [0x1b, '[', 'C'] -> Right
        [0x1b, '[', 'D'] -> Left
        [0x1b, '[', 'H'] -> Home
        [0x1b, '[', 'F'] -> End
        [0x1b, '[', 'Z'] -> BackTab
        [0x1b, '[', '1', '~'] -> Home
        [0x1b, '[', '4', '~'] -> End
        [0x1b, '[', '5', '~'] -> PageUp
        [0x1b, '[', '6', '~'] -> PageDown
        [0x1b, '[', '7', '~'] -> Home
        [0x1b, '[', '8', '~'] -> End
        [0x1b, '[', '1', d, '~'] if '1' <= d && d <= '5' -> F (d - '0')
        [0x1b, '[', '1', d, '~'] if '7' <= d && d <= '9' -> F (d - '0' - 1)
        [0x1b, '[', '2', d, '~'] if '0' <= d && d <= '1' -> F (d - '0' + 9)
        [0x1b, '[', '2', d, '~'] if '3' <= d && d <= '4' -> F (d - '0' + 8)
        [0x1b, '[', v, '~'] if 17 <= v && v <= 21 -> F (v - 11)
        [0x1b, '[', v, '~'] if 23 <= v && v <= 24 -> F (v - 12)
        [0x1b, 'O', val] if 'P' <= val && val <= 'S' -> F (1 + val - 'P')
        [0x1b] -> Esc
        # [0x1b, '[', ..] -> parse csi
        [0x1b, c] -> Alt c
        ['\n'] | ['\r'] -> Return
        ['\t'] -> Tab
        [0] -> Null
        [c] if 0x01 <= c && c <= 0x1a -> Ctrl (c - 0x01 + 'a')
        [c] if 0x1c <= c && c <= 0x1f -> Ctrl (c - 0x1c + '4')
        [c] -> Char c
        _ -> Char 'o'
