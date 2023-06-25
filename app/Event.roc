interface Event
    exposes [
        Event,
        Key,
        fromBytes,
    ]
    imports []

Event : [
    Key Key,
    Unsupported (List U8),
]

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

fromBytes : List U8 -> Event
fromBytes = \event ->
    when event is
        [0x1b, '[', 'A'] -> Key Up
        [0x1b, '[', 'B'] -> Key Down
        [0x1b, '[', 'C'] -> Key Right
        [0x1b, '[', 'D'] -> Key Left
        [0x1b, '[', 'H'] -> Key Home
        [0x1b, '[', 'F'] -> Key End
        [0x1b, '[', 'Z'] -> Key BackTab
        [0x1b, '[', '1', '~'] -> Key Home
        [0x1b, '[', '2', '~'] -> Key Insert
        [0x1b, '[', '3', '~'] -> Key Delete
        [0x1b, '[', '4', '~'] -> Key End
        [0x1b, '[', '5', '~'] -> Key PageUp
        [0x1b, '[', '6', '~'] -> Key PageDown
        [0x1b, '[', '7', '~'] -> Key Home
        [0x1b, '[', '8', '~'] -> Key End
        [0x1b, '[', '1', d, '~'] if '1' <= d && d <= '5' -> Key (F (d - '0'))
        [0x1b, '[', '1', d, '~'] if '7' <= d && d <= '9' -> Key (F (d - '0' - 1))
        [0x1b, '[', '2', d, '~'] if '0' <= d && d <= '1' -> Key (F (d - '0' + 9))
        [0x1b, '[', '2', d, '~'] if '3' <= d && d <= '4' -> Key (F (d - '0' + 8))
        [0x1b, '[', v, '~'] if 17 <= v && v <= 21 -> Key (F (v - 11))
        [0x1b, '[', v, '~'] if 23 <= v && v <= 24 -> Key (F (v - 12))
        [0x1b, '[', '[', val] if 'A' <= val && val <= 'E' -> Key (F (1 + val - 'A'))
        [0x1b, 'O', val] if 'P' <= val && val <= 'S' -> Key (F (1 + val - 'P'))
        [0x1b] -> Key Esc
        [0x1b, c] -> Key (Alt c)
        ['\n'] | ['\r'] -> Key Return
        ['\t'] -> Key Tab
        [0x7f] -> Key Backspace
        [0] -> Key Null
        [c] if 0x01 <= c && c <= 0x1a -> Key (Ctrl (c - 0x01 + 'a'))
        [c] if 0x1c <= c && c <= 0x1f -> Key (Ctrl (c - 0x1c + '4'))
        [c] -> Key (Char c)
        _ -> Unsupported event
