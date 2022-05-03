# On Building...
# Brew Emas Dragon
- The primiary goal is to make **Emacs easier and beautifier** for macOS users.
- This project based on [railwaycat/homebrew-emacsmacport](https://github.com/railwaycat/homebrew-emacsmacport) which uses [emacs-mac](https://bitbucket.org/mituharu/emacs-mac/overview).
- Only newest stable version(currently 28.1) is supported.
- I recommend using this build with [ward-emacs](https://github.com/willbchang/ward-emacs) config, then write your own.

## Features
- **Native mac keybindings**: Most mac users should be able to edit text in Emacs without config.
- **Better defaults**: I have seen lots of same configs in Emacs users' init files, some should be the default.
- **Less annoying messages**: For most cases, people know what they're doing.
- **Minimal Good Looking UI**: Natural title bar, no toolbar icons, no ugly bitmap, bigger window size, Roboto Mono font for English and PingFang SC for Simplified Chinese.


## Install
```sh
brew tap willbchang/homebrew-emacs-dragon
brew install emacs-dragon
```

To disable this tap:
```sh
brew untap willbchang/homebrew-emacs-dragon
```

## License
AGPL-3.0
