# ex_banking

This application was written as a solution to [Heathmont's elixir test](https://github.com/heathmont/elixir-test). Original solution was [written in Erlang](https://github.com/shizzard/heathmont_assignment_erl), so most of documentation there is applicable to this solution as well.

**TL;DR**: Tested on elixir 1.5.2 @ erlang 20.0. `mix test` to test, `iex -S mix` to run.

See also [Standalone `ex_banking` application](https://github.com/shizzard/ex_banking) that may be used as a dependency for elixir umbrella project.

## Known issues

* I was unable to run any common test suite under elixir.

* Due to deprecation of records all data stored in ETS is represented as two-tuple `{user_id, user}`.

* This solution uses lots of erlang STDLIB functions that are not represented in elixir STDLIB (like `lists:partition/2`).
