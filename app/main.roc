app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.11.0/SY4WWMhWQ9NvQgvIthcv15AUeA7rAIJHAHgiaSHGhdY.tar.br",
}

import cli.Stdin
import cli.Stdout
import cli.Task exposing [Task]
import cli.Tty

import Event exposing [Event]

main : Task {} _
main =
    Tty.enableRawMode!
    Task.loop! init \editor ->
        Stdout.write! (render editor)
        input = Stdin.bytes!
        maybeEvent = Event.fromBytes input
        when maybeEvent is
            Ok event ->
                dbg event

                when update editor event is
                    Ok newEditor ->
                        Task.ok (Step newEditor)

                    Err Quit ->
                        Task.ok (Done {})

            Err Unsupported ->
                Task.ok (Step editor)
    Tty.disableRawMode!

Editor : {
    count : U32,
}

init : Editor
init = {
    count: 0,
}

update : Editor, Event -> Result Editor [Quit]
update = \editor, _ ->
    if editor.count >= 5 then
        Err Quit
    else
        Ok { editor & count: editor.count + 1 }

render : Editor -> Str
render = \{} ->
    ""
