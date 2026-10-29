# jimaku

Guidance for anyone, human or agent, changing jimaku. What jimaku is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything jimaku shares with the rest of the kodougu family, and it is the same in every member. This file holds only what is exclusive to jimaku, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into `FAMILY.md` instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/jimaku`](bin/jimaku) | The entry point: it clears inherited `JM_` variables, sources the modules and dispatches the command |
| [`lib/`](lib) | The modules. [`lib/state.sh`](lib/state.sh) declares every global, including the defaults for language, force and the hearing-impaired preference |
| [`man/jimaku.1`](man/jimaku.1) | The man page |
| [`completions/`](completions) | bash, zsh and fish completions |
| [`test/`](test) | The `bats` suite, its helpers, the fake `subliminal` it runs against and the shell matrix runner |
| [`scripts/`](scripts) | Coverage, the coverage gate, the name check, the toolset helper and the release version stamp |

## Names

- Globals carry `JM_`; function-scoped variables carry a per-function `jm_` prefix, such as `jm_fe_`.
- Settings come from `JIMAKU_<NAME>`, such as `JIMAKU_LANGUAGE`; test switches are `JIMAKU_TERMINAL` and `JIMAKU_TEST_SHELLS`.
- Output goes through `jm_say`, `jm_error` and `jm_warning`.

## Behaviour

- jimaku has one job, so a bare `jimaku` on a terminal asks for the folder or video directly, offering the current folder.
- With neither `--language` nor `JIMAKU_LANGUAGE`, it lists twelve common languages and asks for a number or a code, offering `en`; outside a terminal it uses `en`. `--language` wins over `JIMAKU_LANGUAGE`.
- Downloading subtitles changes nothing but the subtitle files beside the videos, so it shows its summary block and starts without a typed confirmation.
- `--language` takes a value; the other options are switches with `--no-` forms where a default exists.

## Domain rules

- jimaku works with subliminal 2.2, the version Ubuntu packages, and with the current one Homebrew ships. It reads `subliminal download --help` once per run and passes `--subtitle-categories` only when it is there.
- A subtitle that cannot be converted to UTF-8 stays exactly as it was, with a warning.
- Tests run against a fake `subliminal` on `PATH`, since the real one needs the network; `file`, `iconv` and `sed` are the real tools.

## Release

- `JIMAKU_VERSION` lives in [`lib/core.sh`](lib/core.sh).
- The tap's `Formula/jimaku.rb` depends on `subliminal`; on Linux the dotfiles install `subliminal` from apt next to jimaku.

## Gaps against FAMILY.md

As of 2026-10-29, closed in the change that removes each line:

- No `make test-linux`, `test/linux-container.sh` or merged local coverage.
- No golden transcripts.
- No `--json` for the list of subtitles a run saved.
