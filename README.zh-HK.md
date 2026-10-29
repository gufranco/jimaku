<div align="center">

<h1>jimaku</h1>

<strong>為一段影片或整個資料夾下載字幕，並全部儲存為 UTF-8，讓任何播放器都能正確顯示重音字母。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文 (香港)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/jimaku/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/jimaku/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/jimaku?style=flat-square&label=release)](https://github.com/gufranco/jimaku/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/jimaku?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速開始</strong></a> |
  <a href="#what-it-does">它做甚麼</a> |
  <a href="#development">開發</a>
</p>

</div>

一條指令，84 個測試，10 個 shell 模組，除了 POSIX 系統和 [subliminal](https://github.com/Diaoul/subliminal) 之外無需安裝任何東西。`jimaku` 是日文「字幕」。姊妹工具 [kakikomi](https://github.com/gufranco/kakikomi)、[kiyome](https://github.com/gufranco/kiyome)、[shiwake](https://github.com/gufranco/shiwake) 和 [yakitsuke](https://github.com/gufranco/yakitsuke) 分別負責寫入磁碟、抹除磁碟、整理資料夾和製作 Video CD。

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

## 快速開始

### 先決條件

| 工具 | 用途 | 安裝 |
|:-----|:-----|:-----|
| `subliminal` | 搜尋字幕網站並下載最吻合的字幕 | `brew install subliminal` 或 `apt install subliminal` |
| `file`、`iconv`、`sed`、`awk` | 判斷字幕的編碼並轉換 | 每個 Linux 和 macOS 系統都內置 |

### 安裝

```bash
brew install gufranco/tap/jimaku
```

或從原始碼安裝：

```bash
git clone https://github.com/gufranco/jimaku.git
cd jimaku
make install
```

`make install` 把工具、man 手冊以及 bash、zsh、fish 補全複製到 `~/.local` 下，並把 `jimaku` 放進 `~/.local/bin`；用 `PREFIX` 可以改變位置。Homebrew formula 安裝同樣的檔案，並一併安裝 subliminal。

### 驗證

```console
$ jimaku doctor
subliminal         ok       /opt/homebrew/bin/subliminal, 2.8.0
file               ok       /usr/bin/file, bsd
iconv              ok       /usr/bin/iconv, bsd
sed                ok       /usr/bin/sed, bsd
awk                ok       /usr/bin/awk, bsd 20200816
```

## 用法

| 指令 | 作用 |
|:-----|:-----|
| `jimaku [options] [video\|folder...]` | 為每段指定的影片，以及每個指定資料夾內的所有影片取得字幕；未指定時使用目前的資料夾 |
| 不帶參數的 `jimaku` | 在終端機中詢問資料夾或影片，預設為目前的資料夾；未設定語言時亦會詢問語言 |
| `jimaku doctor` | 列出 subliminal 和文字工具，以及每個工具的類型和版本 |
| `jimaku version`、`jimaku help` | 列印版本或完整的用法說明 |

| 選項 | 效果 |
|:-----|:-----|
| `--language CODE` | 字幕語言，使用 IETF 代碼，例如 `en`、`pt-BR` 或 `es`。預設為 `JIMAKU_LANGUAGE`，未設定時在終端機中詢問，否則為 `en` |
| `--force`、`--no-force` | 取代已有的字幕，或略過已有字幕的影片。預設取代 |
| `--hearing-impaired`、`--no-hearing-impaired` | 把聽障字幕排在前面或後面。預設排在後面 |
| `--dry-run` | 只列出影片，不下載任何東西 |

| 環境變數 | 效果 |
|:---------|:-----|
| `JIMAKU_LANGUAGE` | 未指定 `--language` 時的字幕語言，例如 `pt-BR`。在 shell 設定檔中設定即成為預設值 |

```bash
jimaku ~/Movies                                    # Movies 內的所有影片
jimaku --language pt-BR "Metropolis (1927).mkv"    # 一段影片，巴西葡萄牙文字幕
jimaku --dry-run .                                 # 查看會處理哪些影片
```

亦可寫成 `--language=en`，`--` 表示選項結束。jimaku 遵循其工具家族共用的命令列約定，見 [FAMILY.md](FAMILY.md)。

<a id="what-it-does"></a>

## 它做甚麼

| 步驟 | 說明 |
|:-----|:-----|
| 找出影片 | 每個資料夾頂層的 `.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov`、`.wmv`、`.webm`、`.mpg`、`.mpeg`、`.ts`、`.m2ts`、`.flv`、`.ogm`、`.divx` 和 `.3gp`，大小寫不限。命令列上指定的檔案不論副檔名都會處理。隱藏檔案和子資料夾保持不動 |
| 交給 subliminal | 每段影片執行一次 `subliminal download`，傳入語言、UTF-8 輸出和所選的優先次序。subliminal 把字幕儲存在影片旁邊，以影片命名 |
| 修正編碼 | 用 `file` 檢查已取得影片旁的所有字幕，以及指定資料夾內的所有 `.srt`。Latin-1、Windows-1252 和 UTF-16 轉為 UTF-8，並去掉 UTF-8 的 BOM，讓只能讀 UTF-8 的播放器和電視亦能正確顯示重音字母 |
| 報告 | 每段影片一行，找不到字幕的影片會發出警告，最後列出總數。只要有一段影片沒有字幕，執行就以失敗結束 |

- 字幕先寫入暫存檔再移到原位，所以中途中斷亦不會留下半個檔案。無法轉換的字幕會保持原樣並發出警告。
- jimaku 支援 Ubuntu 打包的 subliminal 2.2，亦支援目前的版本。如果 subliminal 有字幕類別，`--hearing-impaired` 會把聽障字幕排在前面，預設則排在後面；使用舊版 subliminal 時，預設交由 subliminal 決定。
- 既無 `--language` 亦無 `JIMAKU_LANGUAGE` 時，在終端機中會列出十二種常用語言，接受編號或任何代碼，按 Enter 即選 `en`；在終端機以外則使用 `en`。英文是 `en`，不是 `en-US`：字幕來源列出的英文不帶地區，所以 `en-US` 找不到任何字幕。

<a id="portability"></a>

## 可攜性

全部是 POSIX `sh`，ShellCheck `-o all` 零警告。測試在 macOS 的 `/bin/sh`、系統內置的 bash 3.2 和 zsh、Homebrew 的最新 bash 和 zsh，以及 Ubuntu 的 `dash`、`bash` 和 `zsh` 下執行。

在五種常見工具集上都能執行：使用 GNU 或 uutils coreutils 的 Linux，以及使用 macOS 內置的工具、Homebrew 中較新的版本或 Homebrew 的 uutils 工具的 macOS。macOS 內置而 Homebrew 有較新版本的工具，由 bash 和 zsh 到 iconv 和 file，兩個版本都會測試。CI 在每種工具集上執行全部測試，`jimaku doctor` 會寫出每個工具的類型和版本，例如 `gnu 9.7`、`uutils 0.12.0` 或 `bsd`，讓錯誤報告說明用了哪些工具。

<a id="development"></a>

## 開發

| 指令 | 說明 |
|:-----|:-----|
| `make lint` | 對所有腳本、測試和補全執行 ShellCheck，對 man 手冊執行 mandoc |
| `make test` | 在系統 `sh` 下執行 84 個 `bats` 測試 |
| `make test-all` | 在所有 shell 下執行同樣的測試，macOS 上包括 bash 和 zsh 的兩個版本 |
| `make coverage` | bashcov 行覆蓋率，門檻與 CI 相同，為 100% |

真正的 subliminal 需要網絡，所以測試針對放在 `PATH` 上的假 `subliminal` 執行；`file`、`iconv` 和 `sed` 是真實工具，故障透過放在 `PATH` 上的小型包裝腳本注入。每次推送到 `main` 都會執行 semantic-release：`feat` 或 `fix` 提交會發佈新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `JIMAKU_VERSION` 和 CHANGELOG，並更新 Homebrew formula。

## 授權

[MIT](LICENSE)。
