package "rocterm"
    exposes [
        Clear,
        Color,
        Cursor,
        Event,
        Program,
        Style,
    ]
    packages {
        cli: "../basic-cli/src/main.roc",
    }
