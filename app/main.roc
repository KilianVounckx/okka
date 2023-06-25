app "okka"
    packages {
        # cli: "https://github.com/roc-lang/basic-cli/releases/download/0.4.0/DI4lqn7LIZs8ZrCDUgLK-tHHpQmxGF1ZrlevRKq5LXk.tar.br",
        # cli: "https://github.com/roc-lang/basic-cli/releases/download/0.4.0/N2H7rEuSe0dl6MJunQsAF7spj23mqj9SBd5kgYVjVz8.tar.gz",
        cli: "../basic-cli/src/main.roc",
    }
    imports [
        cli.Stdin,
        cli.Stdout,
        cli.Task.{ Task },
        cli.Tty,
        Clear,
    ]
    provides [main] to cli

main : Task {} I32
main =
    {} <- Tty.enableRawMode |> Task.await

    {} <-
        Task.loop (initialWorld {}) \world ->
            {} <- display world |> Stdout.write |> Task.await
            event <- Stdin.bytes |> Task.await
            Task.ok (update world event)
        |> Task.await

    {} <- Tty.disableRawMode |> Task.await
    Task.ok {}

World : {}

initialWorld : {} -> World
initialWorld = \{} ->
    {}

update : World, List U8 -> [Step World, Done {}]
update = \{}, event ->
    when event is
        ['q'] -> Done {}
        _ -> Step {}

display : World -> Str
display = \{} ->
    Clear.all
