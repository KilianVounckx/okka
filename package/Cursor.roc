module [
    goto,
    left,
    right,
    up,
    down,
    hide,
    show,
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
