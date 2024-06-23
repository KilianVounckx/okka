module [
    Event,
    KeyEvent,
    fromBytes,
]

Event : [
    Key KeyEvent,
]

KeyEvent : [
    Backspace,
    Left,
    ShiftLeft,
    AltLeft,
    CtrlLeft,
    Right,
    ShiftRight,
    AltRight,
    CtrlRight,
    Up,
    ShiftUp,
    AltUp,
    CtrlUp,
    Down,
    ShiftDown,
    AltDown,
    CtrlDown,
    Home,
    ShiftHome,
    AltHome,
    CtrlHome,
    End,
    ShiftEnd,
    AltEnd,
    CtrlEnd,
    PageUp,
    PageDown,
    Backtab,
    Delete,
    Insert,
    F U8,
    Char U8,
    Alt U8,
    Ctrl U8,
    Null,
    Esc,
]

fromBytes : List U8 -> Result Event [Unsupported]
fromBytes = \bytes ->
    when bytes is
        [0x1b, 'O', c] if 'P' <= c && c <= 'S' -> Ok (Key (F (1 + c - 'P')))
        [0x1b, '[', .. as rest] -> parseCsi rest
        [0x1b, c] -> Ok (Key (Alt c))
        [0x1b] -> Ok (Key Esc)
        ['\n'] | ['\r'] -> Ok (Key (Char '\n'))
        ['\t'] -> Ok (Key (Char '\t'))
        [0x7f] -> Ok (Key Backspace)
        [c] if 0x01 <= c && c <= 0x1a -> Ok (Key (Ctrl (c - 0x1 + 'a')))
        [c] if 0x1c <= c && c <= 0x1f -> Ok (Key (Ctrl (c - 0x1c + '4')))
        [0] -> Ok (Key Null)
        [c] -> Ok (Key (Char c))
        _ -> Err Unsupported

parseCsi : List U8 -> Result Event [Unsupported]
parseCsi = \bytes ->
    when bytes is
        ['1', '~'] -> Ok (Key Home)
        ['2', '~'] -> Ok (Key Insert)
        ['3', '~'] -> Ok (Key Delete)
        ['4', '~'] -> Ok (Key End)
        ['5', '~'] -> Ok (Key PageUp)
        ['6', '~'] -> Ok (Key PageDown)
        ['7', '~'] -> Ok (Key Home)
        ['8', '~'] -> Ok (Key End)
        ['1', '1', '~'] -> Ok (Key (F 1))
        ['1', '2', '~'] -> Ok (Key (F 2))
        ['1', '3', '~'] -> Ok (Key (F 3))
        ['1', '4', '~'] -> Ok (Key (F 4))
        ['1', '5', '~'] -> Ok (Key (F 5))
        ['1', '7', '~'] -> Ok (Key (F 6))
        ['1', '8', '~'] -> Ok (Key (F 7))
        ['1', '9', '~'] -> Ok (Key (F 8))
        ['2', '0', '~'] -> Ok (Key (F 9))
        ['2', '1', '~'] -> Ok (Key (F 10))
        ['2', '3', '~'] -> Ok (Key (F 11))
        ['2', '4', '~'] -> Ok (Key (F 12))
        ['1', ';', '2', 'A'] -> Ok (Key ShiftUp)
        ['1', ';', '2', 'B'] -> Ok (Key ShiftDown)
        ['1', ';', '2', 'C'] -> Ok (Key ShiftRight)
        ['1', ';', '2', 'D'] -> Ok (Key ShiftLeft)
        ['1', ';', '2', 'F'] -> Ok (Key ShiftEnd)
        ['1', ';', '2', 'H'] -> Ok (Key ShiftHome)
        ['1', ';', '3', 'A'] -> Ok (Key AltUp)
        ['1', ';', '3', 'B'] -> Ok (Key AltDown)
        ['1', ';', '3', 'C'] -> Ok (Key AltRight)
        ['1', ';', '3', 'D'] -> Ok (Key AltLeft)
        ['1', ';', '3', 'F'] -> Ok (Key AltEnd)
        ['1', ';', '3', 'H'] -> Ok (Key AltHome)
        ['1', ';', '5', 'A'] -> Ok (Key CtrlUp)
        ['1', ';', '5', 'B'] -> Ok (Key CtrlDown)
        ['1', ';', '5', 'C'] -> Ok (Key CtrlRight)
        ['1', ';', '5', 'D'] -> Ok (Key CtrlLeft)
        ['1', ';', '5', 'F'] -> Ok (Key CtrlEnd)
        ['1', ';', '5', 'H'] -> Ok (Key CtrlHome)
        ['[', c] if 'A' <= c && c <= 'E' -> Ok (Key (F (1 + c - 'A')))
        ['A'] -> Ok (Key Up)
        ['B'] -> Ok (Key Down)
        ['C'] -> Ok (Key Right)
        ['D'] -> Ok (Key Left)
        ['F'] -> Ok (Key End)
        ['H'] -> Ok (Key Home)
        ['Z'] -> Ok (Key Backtab)
        _ -> Err Unsupported
