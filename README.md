<div align="center">

<h1>jimaku</h1>

<strong>Download subtitles for a video or a whole folder, and save every one as UTF-8 so accents show right on any player.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/jimaku/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/jimaku/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/jimaku?style=flat-square&label=release)](https://github.com/gufranco/jimaku/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/jimaku?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> |
  <a href="#what-it-does">What it does</a> |
  <a href="#development">Development</a>
</p>

</div>

One command, 84 tests, 10 shell modules, and nothing to install beyond a POSIX system and [subliminal](https://github.com/Diaoul/subliminal). `jimaku` is 字幕, Japanese for subtitles. Its companions [kakikomi](https://github.com/gufranco/kakikomi), [kiyome](https://github.com/gufranco/kiyome), [shiwake](https://github.com/gufranco/shiwake) and [yakitsuke](https://github.com/gufranco/yakitsuke) write disks, wipe disks, sort folders and burn Video CDs.

---

```console
$ jimaku --language pt-BR ~/Movies

Videos: 3 in /Users/me/Movies
Plan:   pt-BR subtitles, saved as UTF-8 next to each video
        any subtitle already there is replaced

/Users/me/Movies/Metropolis (1927).mkv: saved a subtitle in pt-BR.
/Users/me/Movies/Metropolis (1927).pt-BR.srt: converted from iso-8859-1 to
UTF-8.
/Users/me/Movies/Nosferatu (1922).mp4: saved a subtitle in pt-BR.
jimaku: warning: no pt-BR subtitle found for /Users/me/Movies/The General
(1926).avi.
Saved pt-BR subtitles for 2 of 3 videos.
```

<a id="quick-start"></a>

## Quick start

### Prerequisites

| Tool | Why | Install |
|:-----|:----|:--------|
| `subliminal` | Searches the subtitle providers and downloads the best match | `brew install subliminal` or `apt install subliminal` |
| `file`, `iconv`, `sed`, `awk` | Tell a subtitle's encoding and convert it | Part of every Linux and macOS system |

### Install

```bash
brew install gufranco/tap/jimaku
```

Or from source:

```bash
git clone https://github.com/gufranco/jimaku.git
cd jimaku
make install
```

`make install` copies the tool, its man page and its bash, zsh and fish completions under `~/.local`, and puts `jimaku` in `~/.local/bin`; set `PREFIX` to change that. The Homebrew formula installs the same files and subliminal with them.

### Verify

```console
$ jimaku doctor
subliminal         ok       /opt/homebrew/bin/subliminal, 2.8.0
file               ok       /usr/bin/file, bsd
iconv              ok       /usr/bin/iconv, bsd
sed                ok       /usr/bin/sed, bsd
awk                ok       /usr/bin/awk, bsd 20200816
```

## Usage

| Command | Purpose |
|:--------|:--------|
| `jimaku [options] [video\|folder...]` | Fetch a subtitle for each video, and for every video in each folder; the current folder when none is given |
| `jimaku` with no arguments | Ask for the folder or video, offering the current folder, and then for the language when none is set, when run in a terminal |
| `jimaku doctor` | List subliminal and the text tools, with the flavor and version of each |
| `jimaku version`, `jimaku help` | Print the version or the full usage page |

| Option | Effect |
|:-------|:-------|
| `--language CODE` | The subtitle language, an IETF code such as `en`, `pt-BR` or `es`. Default `JIMAKU_LANGUAGE`, else asked in a terminal, else `en` |
| `--force`, `--no-force` | Replace a subtitle that is already there, or skip a video that has one. Default yes |
| `--hearing-impaired`, `--no-hearing-impaired` | Put subtitles for the hearing impaired first, or last. Default no |
| `--dry-run` | List every video and download nothing |

| Variable | Effect |
|:---------|:-------|
| `JIMAKU_LANGUAGE` | The subtitle language when `--language` is not given, such as `pt-BR`. Set it in your shell profile to make it your default |

```bash
jimaku ~/Movies                                    # every video in Movies
jimaku --language pt-BR "Metropolis (1927).mkv"    # one video, in Brazilian Portuguese
jimaku --dry-run .                                 # see which videos would be fetched
```

`--language=en` works too, and `--` ends the options. jimaku follows the shared command-line contract of its family, described in [FAMILY.md](FAMILY.md).

<a id="what-it-does"></a>

## What it does

| Step | Detail |
|:-----|:-------|
| Find the videos | Every `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov`, `.wmv`, `.webm`, `.mpg`, `.mpeg`, `.ts`, `.m2ts`, `.flv`, `.ogm`, `.divx` and `.3gp` at the top of each folder, in any case. A file named on the command line is used whatever its extension. Hidden files and subfolders are left alone |
| Ask subliminal | One `subliminal download` per video, with the language, UTF-8 output and the chosen preferences. subliminal saves the subtitle next to the video, named after it |
| Fix the encoding | Every subtitle beside a fetched video, and every `.srt` in a folder that was given, is checked with `file`. Latin-1, Windows-1252 and UTF-16 become UTF-8, and a UTF-8 byte order mark is removed, so players and TVs that only read UTF-8 show accents right |
| Report | One line per video, a warning for each video with no subtitle out there, and a total. The run fails when any video got none |

- A subtitle is rewritten through a temporary file and then moved into place, so an interrupted run never leaves half a file. A subtitle that cannot be converted stays exactly as it was, with a warning.
- jimaku works with subliminal 2.2, the version Ubuntu packages, and with the current one. Where subliminal has subtitle categories, `--hearing-impaired` puts those subtitles first and the default puts them last; with an older subliminal, the default leaves the choice to subliminal.
- With neither `--language` nor `JIMAKU_LANGUAGE`, a run in a terminal lists twelve common languages and takes a number or any code, with Enter picking `en`; outside a terminal it uses `en`. English is `en`, never `en-US`: the subtitle providers list English without a region, so `en-US` matches nothing.

## Portability

Everything is POSIX `sh` with ShellCheck `-o all` at zero findings. The suites run on macOS under `/bin/sh`, the system's bash 3.2 and zsh, and Homebrew's current bash and zsh, and on Ubuntu under `dash`, `bash` and `zsh`.

Every run works on the five toolsets in common use: Linux with GNU or uutils coreutils, and macOS with the tools it ships, Homebrew's newer builds of them, or Homebrew's uutils tools. Every tool macOS ships that Homebrew also builds newer, from bash and zsh to iconv and file, is tested in both builds. CI runs the whole suite on each, and `jimaku doctor` names the flavor and version of each tool, such as `gnu 9.7`, `uutils 0.12.0` or `bsd`, so a bug report says which tools ran.

<a id="development"></a>

## Development

| Command | Description |
|:--------|:------------|
| `make lint` | ShellCheck on every script, test and completion, and mandoc on the man page |
| `make test` | The 84 `bats` tests under the system `sh` |
| `make test-all` | The same tests under every shell, both builds of bash and zsh included on macOS |
| `make coverage` | bashcov line coverage, with the 100% gate CI enforces |

The tests run against a fake `subliminal` placed on `PATH`, since the real one needs the network; `file`, `iconv` and `sed` are the real tools, with failures injected through small wrappers on `PATH`. Every push to `main` runs semantic-release: a `feat` or `fix` commit publishes a release, updates `JIMAKU_VERSION` in [`lib/core.sh`](lib/core.sh) and the CHANGELOG, and bumps the Homebrew formula.

## License

[MIT](LICENSE).
