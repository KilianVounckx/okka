module [
    Style,
    Color,
    style,
]

Style : [
    Reset,
    Bold [On, Off],
    Faint [On, Off],
    Italic [On, Off],
    Underline [On, Off],
    Blink [On, Off],
    InvertColor [On, Off],
    Strikethrough [On, Off],
    Foreground Color,
    Background Color,
]

Color : [
    Default,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    BrightBlack,
    BrightRed,
    BrightGreen,
    BrightYellow,
    BrightBlue,
    BrightMagenta,
    BrightCyan,
    BrightWhite,
]

style : List Style -> Str
style = \styles ->
    inner =
        styles
        |> List.map \s ->
            toStr s
        |> Str.joinWith ";"
    "\u(1b)[$(inner)m"

toStr : Style -> Str
toStr = \s ->
    when s is
        Reset -> "0"
        Bold On -> "1"
        Faint On -> "2"
        Italic On -> "3"
        Underline On -> "4"
        Blink On -> "5"
        InvertColor On -> "7"
        Strikethrough On -> "9"
        Bold Off -> "21"
        Faint Off -> "22"
        Italic Off -> "23"
        Underline Off -> "24"
        Blink Off -> "25"
        InvertColor Off -> "27"
        Strikethrough Off -> "29"
        Foreground color -> fgToStr color
        Background color -> bgToStr color

fgToStr : Color -> Str
fgToStr = \color ->
    when color is
        Default -> "39"
        Black -> "30"
        Red -> "31"
        Green -> "32"
        Yellow -> "33"
        Blue -> "34"
        Magenta -> "35"
        Cyan -> "36"
        White -> "37"
        BrightBlack -> "90"
        BrightRed -> "91"
        BrightGreen -> "92"
        BrightYellow -> "93"
        BrightBlue -> "94"
        BrightMagenta -> "95"
        BrightCyan -> "96"
        BrightWhite -> "97"

bgToStr : Color -> Str
bgToStr = \color ->
    when color is
        Default -> "49"
        Black -> "40"
        Red -> "41"
        Green -> "42"
        Yellow -> "43"
        Blue -> "44"
        Magenta -> "45"
        Cyan -> "46"
        White -> "47"
        BrightBlack -> "100"
        BrightRed -> "101"
        BrightGreen -> "102"
        BrightYellow -> "103"
        BrightBlue -> "104"
        BrightMagenta -> "105"
        BrightCyan -> "106"
        BrightWhite -> "107"

