module [
    goto,
    left,
    right,
    up,
    down,
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

goto : { row : U16, column : U16 } -> Str
goto = \{ row, column } ->
    "\u(1b)[$(Num.toStr (row + 1));$(Num.toStr (column + 1))H"

left : U16 -> Str
left = \amount ->
    "\u(1b)[$(Num.toStr amount)D"

right : U16 -> Str
right = \amount ->
    "\u(1b)[$(Num.toStr amount)C"

up : U16 -> Str
up = \amount ->
    "\u(1b)[$(Num.toStr amount)A"

down : U16 -> Str
down = \amount ->
    "\u(1b)[$(Num.toStr amount)B"

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
