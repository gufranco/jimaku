<div align="center">

<h1>jimaku</h1>

<strong>为一个视频或整个文件夹下载字幕，并全部保存为 UTF-8，让任何播放器都能正确显示重音字母。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://github.com/gufranco/jimaku/actions/workflows/ci.yml/badge.svg)](https://github.com/gufranco/jimaku/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/jimaku)](https://github.com/gufranco/jimaku/releases)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![shell](https://img.shields.io/badge/shell-POSIX%20sh-lightgrey)](#portability)

<p align="center">
  <a href="#quick-start"><strong>快速开始</strong></a> |
  <a href="#what-it-does">它做什么</a> |
  <a href="#development">开发</a>
</p>

</div>

一个命令，77 个测试，10 个 shell 模块，除 POSIX 系统和 [subliminal](https://github.com/Diaoul/subliminal) 外无需安装任何东西。`jimaku` 是日语"字幕"。它的姊妹工具 [kakikomi](https://github.com/gufranco/kakikomi)、[kiyome](https://github.com/gufranco/kiyome)、[shiwake](https://github.com/gufranco/shiwake) 和 [yakitsuke](https://github.com/gufranco/yakitsuke) 分别负责写入磁盘、擦除磁盘、整理文件夹和制作 Video CD。

---

```console
$ jimaku --language pt-BR ~/Movies

Videos: 3 in /Users/me/Movies
Plan:   pt-BR subtitles, saved as UTF-8 next to each video
        any subtitle already there is replaced

/Users/me/Movies/Metropolis (1927).mkv: saved a subtitle in pt-BR.
/Users/me/Movies/Metropolis (1927).en.srt: converted from iso-8859-1 to UTF-8.
/Users/me/Movies/Nosferatu (1922).mp4: saved a subtitle in pt-BR.
jimaku: warning: no pt-BR subtitle found for /Users/me/Movies/The General (1926).avi.
Saved pt-BR subtitles for 2 of 3 videos.
```

<a id="quick-start"></a>

## 快速开始

### 前提条件

| 工具 | 用途 | 安装 |
|:-----|:-----|:-----|
| `subliminal` | 搜索字幕网站并下载最匹配的字幕 | `brew install subliminal` 或 `apt install subliminal` |
| `file`、`iconv`、`sed`、`awk` | 判断字幕的编码并转换 | 每个 Linux 和 macOS 系统都自带 |

### 安装

```bash
brew install gufranco/tap/jimaku
```

或从源码安装：

```bash
git clone https://github.com/gufranco/jimaku.git
cd jimaku
make install
```

`make install` 把工具、man 手册以及 bash、zsh、fish 补全复制到 `~/.local` 下，并把 `jimaku` 放进 `~/.local/bin`；用 `PREFIX` 可以改变位置。Homebrew formula 安装同样的文件，并一起安装 subliminal。

### 验证

```console
$ jimaku doctor
subliminal         ok       /opt/homebrew/bin/subliminal, 2.8.0
file               ok       /usr/bin/file, bsd
iconv              ok       /usr/bin/iconv, bsd
sed                ok       /usr/bin/sed, bsd
awk                ok       /usr/bin/awk, bsd 20200816
```

## 用法

| 命令 | 作用 |
|:-----|:-----|
| `jimaku [options] [video\|folder...]` | 为每个给定的视频，以及每个给定文件夹中的所有视频获取字幕；未给定时使用当前文件夹 |
| 不带参数的 `jimaku` | 在终端中询问文件夹或视频，默认为当前文件夹；未设定语言时也会询问语言 |
| `jimaku doctor` | 列出 subliminal 和文本工具，以及每个工具的类型和版本 |
| `jimaku version`、`jimaku help` | 打印版本或完整的用法说明 |

| 选项 | 效果 |
|:-----|:-----|
| `--language CODE` | 字幕语言，使用 IETF 代码，例如 `en`、`pt-BR` 或 `es`。默认为 `JIMAKU_LANGUAGE`，未设置时在终端中询问，否则为 `en` |
| `--force`、`--no-force` | 替换已有的字幕，或跳过已有字幕的视频。默认替换 |
| `--hearing-impaired`、`--no-hearing-impaired` | 把听障字幕排在前面或后面。默认排在后面 |
| `--dry-run` | 只列出视频，不下载任何东西 |

| 环境变量 | 效果 |
|:---------|:-----|
| `JIMAKU_LANGUAGE` | 未指定 `--language` 时的字幕语言，例如 `pt-BR`。在 shell 配置文件中设置即成为默认值 |

```bash
jimaku ~/Movies                                    # Movies 中的所有视频
jimaku --language pt-BR "Metropolis (1927).mkv"    # 一个视频，巴西葡萄牙语字幕
jimaku --dry-run .                                 # 查看会处理哪些视频
```

也可以写成 `--language=en`，`--` 表示选项结束。jimaku 遵循其工具家族共享的命令行约定，见 [FAMILY.md](FAMILY.md)。

<a id="what-it-does"></a>

## 它做什么

| 步骤 | 说明 |
|:-----|:-----|
| 找出视频 | 每个文件夹顶层的 `.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov`、`.wmv`、`.webm`、`.mpg`、`.mpeg`、`.ts`、`.m2ts`、`.flv`、`.ogm`、`.divx` 和 `.3gp`，大小写不限。命令行上指定的文件不论扩展名都会处理。隐藏文件和子文件夹保持不动 |
| 交给 subliminal | 每个视频运行一次 `subliminal download`，传入语言、UTF-8 输出和所选的优先顺序。subliminal 把字幕保存在视频旁边，以视频命名 |
| 修正编码 | 用 `file` 检查已获取视频旁的所有字幕，以及给定文件夹中的所有 `.srt`。Latin-1、Windows-1252 和 UTF-16 转为 UTF-8，并去掉 UTF-8 的 BOM，让只能读 UTF-8 的播放器和电视也能正确显示重音字母 |
| 报告 | 每个视频一行，找不到字幕的视频给出警告，最后给出总数。只要有一个视频没有字幕，运行就以失败结束 |

- 字幕先写入临时文件再移到原位，所以中途中断也不会留下半个文件。无法转换的字幕会保持原样并给出警告。
- jimaku 支持 Ubuntu 打包的 subliminal 2.2，也支持当前版本。如果 subliminal 有字幕类别，`--hearing-impaired` 会把听障字幕排在前面，默认则排在后面；使用旧版 subliminal 时，默认交由 subliminal 决定。
- 既没有 `--language` 也没有 `JIMAKU_LANGUAGE` 时，在终端中会列出十二种常用语言，接受编号或任意代码，按 Enter 即选 `en`；在终端之外则使用 `en`。英语是 `en`，不是 `en-US`：字幕提供方列出的英语不带地区，所以 `en-US` 找不到任何字幕。

<a id="portability"></a>

## 可移植性

全部是 POSIX `sh`，ShellCheck `-o all` 零警告。测试在 macOS 的 `/bin/sh`、系统自带的 bash 3.2 和 zsh、Homebrew 的最新 bash 和 zsh，以及 Ubuntu 的 `dash`、`bash` 和 `zsh` 下运行。

在五种常见工具集上都能运行：使用 GNU 或 uutils coreutils 的 Linux，以及使用 macOS 自带的工具、Homebrew 中更新的版本或 Homebrew 的 uutils 工具的 macOS。macOS 自带而 Homebrew 有更新版本的工具，从 bash 和 zsh 到 iconv 和 file，两个版本都会测试。CI 在每种工具集上运行全部测试，`jimaku doctor` 会写出每个工具的类型和版本，例如 `gnu 9.7`、`uutils 0.12.0` 或 `bsd`，这样错误报告就能说明用了哪些工具。

<a id="development"></a>

## 开发

| 命令 | 说明 |
|:-----|:-----|
| `make lint` | 对所有脚本、测试和补全运行 ShellCheck，对 man 手册运行 mandoc |
| `make test` | 在系统 `sh` 下运行 65 个 `bats` 测试 |
| `make test-all` | 在所有 shell 下运行同样的测试，macOS 上包括 bash 和 zsh 的两个版本 |
| `make coverage` | bashcov 行覆盖率，门槛与 CI 相同，为 100% |

真正的 subliminal 需要网络，所以测试针对放在 `PATH` 上的假 `subliminal` 运行；`file`、`iconv` 和 `sed` 是真实工具，故障通过放在 `PATH` 上的小包装脚本注入。每次推送到 `main` 都会运行 semantic-release：`feat` 或 `fix` 提交会发布新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `JIMAKU_VERSION` 和 CHANGELOG，并更新 Homebrew formula。

## 许可证

[MIT](LICENSE)。
