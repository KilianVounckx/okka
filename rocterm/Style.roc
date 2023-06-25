interface Style
    exposes [
        reset,
        bold,
        faint,
        italic,
        underline,
        blink,
        invert,
        crossedOut,
        noBold,
        noFaint,
        noItalic,
        noUnderline,
        noBlink,
        noInvert,
        noCrossedOut,
        framed,
    ]
    imports []

reset : Str
reset = "\u(1b)[m"

bold : Str
bold = "\u(1b)[1m"

faint : Str
faint = "\u(1b)[2m"

italic : Str
italic = "\u(1b)[3m"

underline : Str
underline = "\u(1b)[4m"

blink : Str
blink = "\u(1b)[5m"

invert : Str
invert = "\u(1b)[7m"

crossedOut : Str
crossedOut = "\u(1b)[9m"

noBold : Str
noBold = "\u(1b)[21m"

noFaint : Str
noFaint = "\u(1b)[22m"

noItalic : Str
noItalic = "\u(1b)[23m"

noUnderline : Str
noUnderline = "\u(1b)[24m"

noBlink : Str
noBlink = "\u(1b)[25m"

noInvert : Str
noInvert = "\u(1b)[27m"

noCrossedOut : Str
noCrossedOut = "\u(1b)[29m"

framed : Str
framed = "\u(1b)[51m"

