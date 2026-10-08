# HackermacUI Brewfile — core stack
#
# Single source of truth for required Homebrew dependencies. Optional groups
# live in sibling Brewfiles so they can be installed separately:
#
#   brew bundle --file Brewfile          # core (this file)
#   brew bundle --file Brewfile.dev      # optional local development tools
#   brew bundle --file Brewfile.extras   # optional menu-bar cleanup (Ice)
#
# scripts/install-deps.sh drives these with the same y/N prompts it always
# has; run `brew bundle` directly if you want the core stack without prompts.

tap "nikitabobko/tap"
tap "FelixKratz/formulae"

# Tiling, menu bar, terminal.
cask "nikitabobko/tap/aerospace"
cask "swiftbar"
cask "ghostty"

# Font used by configs/ghostty/config (font-family / window-title-font-family).
cask "font-jetbrains-mono-nerd-font"

# Focus border, repo/shell tooling, and shell ergonomics.
brew "borders"
brew "gh"
brew "fzf"
brew "atuin"
brew "zoxide"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fastfetch"
brew "bat"
brew "ripgrep"

# Personal apps opened by AeroSpace hotkeys (Cmd+B, Cmd+O). Not installed by
# default because they are a matter of personal taste, not a runtime
# dependency; uncomment or `brew install --cask <name>` if you want them.
# cask "google-chrome"
# cask "obsidian"
