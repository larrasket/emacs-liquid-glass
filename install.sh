#!/usr/bin/env sh
set -eu

copy_app=1

for arg in "$@"; do
  case "$arg" in
    --no-copy-app)
      copy_app=0
      ;;
    -h|--help)
      printf '%s\n' "Usage: ./install.sh [--no-copy-app]"
      exit 0
      ;;
    *)
      printf '%s\n' "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

mkdir -p "$HOME/.config/emacs-plus"
cp "$repo_dir/patches/ns-glass-effect.patch" "$HOME/.config/emacs-plus/ns-glass-effect.patch"
cp "$repo_dir/config/build.yml" "$HOME/.config/emacs-plus/build.yml"

brew tap d12frosted/emacs-plus
HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall emacs-plus@31 --build-from-source
brew postinstall d12frosted/emacs-plus/emacs-plus@31

if [ "$copy_app" -eq 1 ]; then
  rsync -a --delete /opt/homebrew/opt/emacs-plus@31/Emacs.app/ /Applications/Emacs.app/
  rsync -a --delete "/opt/homebrew/opt/emacs-plus@31/Emacs Client.app/" "/Applications/Emacs Client.app/"
fi

printf '%s\n' "Done. Fully quit and reopen Emacs, or restart the daemon."
