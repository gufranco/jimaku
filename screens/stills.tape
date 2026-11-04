Source common.tape
Output scratch.gif
Set Height 1100
Hide
Type ". ./setup.sh"
Enter
Sleep 1s
Show
Sleep 800ms
Type "jimaku --dry-run --language en films"
Enter
Sleep 4s
Screenshot dry-run.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "jimaku --language en films/Charade*"
Enter
Sleep 3s
Enter
Sleep 25s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "jimaku --no-force --language en films/Charade*.mkv"
Enter
Sleep 3s
Enter
Sleep 4s
Screenshot kept.png
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "jimaku --language en Music"
Enter
Sleep 3s
Screenshot error.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "jimaku doctor"
Enter
Sleep 10s
Screenshot doctor.png
Sleep 1s
Hide
Type "clear"
Enter
Show
Sleep 800ms
Type "for t in kodougu catppuccin-mocha dracula nord gruvbox tokyo-night; do jimaku --theme $t version; done"
Enter
Sleep 8s
Screenshot themes.png
Sleep 1s
Sleep 1s
