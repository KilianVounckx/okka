module [
    Color,
    foreground,
    background,
]

Color : [
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    Reset,
]

foreground : Color -> Str
foreground = \color ->
    when color is
        Black -> "\u(1b)[38;5;0m"
        Red -> "\u(1b)[38;5;1m"
        Green -> "\u(1b)[38;5;2m"
        Yellow -> "\u(1b)[38;5;3m"
        Blue -> "\u(1b)[38;5;4m"
        Magenta -> "\u(1b)[38;5;5m"
        Cyan -> "\u(1b)[38;5;6m"
        White -> "\u(1b)[38;5;7m"
        Reset -> "\u(1b)[39m"

background : Color -> Str
background = \color ->
    when color is
        Black -> "\u(1b)[48;5;0m"
        Red -> "\u(1b)[48;5;1m"
        Green -> "\u(1b)[48;5;2m"
        Yellow -> "\u(1b)[48;5;3m"
        Blue -> "\u(1b)[48;5;4m"
        Magenta -> "\u(1b)[48;5;5m"
        Cyan -> "\u(1b)[48;5;6m"
        White -> "\u(1b)[48;5;7m"
        Reset -> "\u(1b)[49m"
