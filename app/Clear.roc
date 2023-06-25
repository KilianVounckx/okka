interface Clear
    exposes [
        all,
        afterCursor,
        beforeCursor,
        currentLine,
        untilNewLine,
        fromNewLineUntilCursor,
    ]
    imports []

all : Str
all = "\u(1b)[2J"

afterCursor : Str
afterCursor = "\u(1b)[J"

beforeCursor : Str
beforeCursor = "\u(1b)[1J"

currentLine : Str
currentLine = "\u(1b)[2K"

untilNewLine : Str
untilNewLine = "\u(1b)[K"

fromNewLineUntilCursor : Str
fromNewLineUntilCursor = "\u(1b)[1K"
