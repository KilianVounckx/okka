app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.11.0/SY4WWMhWQ9NvQgvIthcv15AUeA7rAIJHAHgiaSHGhdY.tar.br",
}

import cli.Stdout
import cli.Task exposing [Task]

main : Task {} _
main =
    Stdout.line! "Hello, World!"
