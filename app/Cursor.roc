interface Cursor
    exposes [
        up,
        down,
        left,
        right,
        goto,
        hide,
        show,
        save,
        restore,
        blinkingBlock,
        steadyBlock,
        blinkingUnderline,
        steadyUnderline,
        blinkingBar,
        steadyBar,
    ]
    imports []

up : U16 -> Str
up = \x ->
    xStr = Num.toStr x
    "\u(1b)[\(xStr)A"

down : U16 -> Str
down = \x ->
    xStr = Num.toStr x
    "\u(1b)[\(xStr)B"

left : U16 -> Str
left = \x ->
    xStr = Num.toStr x
    "\u(1b)[\(xStr)D"

right : U16 -> Str
right = \x ->
    xStr = Num.toStr x
    "\u(1b)[\(xStr)C"

goto : U16, U16 -> Str
goto = \x, y ->
    xStr = Num.toStr x
    yStr = Num.toStr y
    "\u(1b)[\(yStr);\(xStr)H"

hide : Str
hide = "\u(1b)[?25l"

show : Str
show = "\u(1b)[?25h"

save : Str
save = "\u(1b)[s"

restore : Str
restore = "\u(1b)[u"

blinkingBlock : Str
blinkingBlock = "\u(1b)[\u(31) q"

steadyBlock : Str
steadyBlock = "\u(1b)[\u(32) q"

blinkingUnderline : Str
blinkingUnderline = "\u(1b)[\u(33) q"

steadyUnderline : Str
steadyUnderline = "\u(1b)[\u(34) q"

blinkingBar : Str
blinkingBar = "\u(1b)[\u(35) q"

steadyBar : Str
steadyBar = "\u(1b)[\u(36) q"
