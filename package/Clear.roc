module [
    all,
    beforeCursor,
    afterCursor,
    line,
    fromNewline,
    untilNewline,
]

all : Str
all = "\u(1b)[2J"

beforeCursor : Str
beforeCursor = "\u(1b)[1J"

afterCursor : Str
afterCursor = "\u(1b)[J"

line : Str
line = "\u(1b)[2K"

fromNewline : Str
fromNewline = "\u(1b)[1K"

untilNewline : Str
untilNewline = "\u(1b)[K"
