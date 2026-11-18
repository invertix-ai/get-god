#!/bin/bash
# The installer of God, for a member of the team. It is public and holds nothing: no key, no code of God, nobody's
# data. It signs you in to GitHub and fetches the team's private repository, which GitHub gives only to members of the
# organisation; then it runs that repository's own setup on your Mac.
#   curl -fsSL https://god.invertix.ai/install.sh | bash
set -euo pipefail
REPO="${GOD_REPO:-invertix-ai/god}"
DEST="${GOD_DIR:-$HOME/god}"
say() { printf '\n== %s\n' "$1"; }
stop() { printf '\n%s\n' "$1" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || stop "God runs on a Mac. This is not one."
# Piped from curl, this script is the standard input: questions are asked on the terminal itself.
[ -r /dev/tty ] || stop "Run this in a terminal window: it has a few questions for you."
ask() { local a; printf '%s ' "$1" > /dev/tty; IFS= read -r a < /dev/tty; printf '%s' "$a"; }

say "1/4 Tools"
command -v brew >/dev/null 2>&1 || stop "Install Homebrew first (https://brew.sh), then run this again."
command -v gh >/dev/null 2>&1 || brew install gh
command -v git >/dev/null 2>&1 || stop "Install the Xcode command line tools first: xcode-select --install"

say "2/4 Your GitHub account"
gh auth status --hostname github.com >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web < /dev/tty
WHO="$(gh api user -q .login 2>/dev/null || true)"
[ -n "$WHO" ] || stop "The GitHub sign-in did not finish. Run this again."
if ! gh repo view "$REPO" --json name -q .name >/dev/null 2>&1; then
  stop "You are signed in to GitHub as $WHO, and that account cannot open the team's repository.
Ask your team lead to add $WHO to the organisation, then run this again. Nothing was installed."
fi
echo "   signed in as $WHO, with access"

say "3/4 The code"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only || stop "$DEST has changes of its own, so it was not updated. Sort that out (git -C $DEST status), then run this again."
elif [ -e "$DEST" ]; then
  stop "$DEST is already there and is not God. Move it away, or choose another place: GOD_DIR=~/somewhere bash install.sh"
else
  gh repo clone "$REPO" "$DEST" -- --quiet
fi
[ -f "$DEST/setup.sh" ] || stop "The repository came without its setup. Tell your team lead."
echo "   in $DEST"

say "4/4 You"
# Each answer can also be given beforehand (GOD_NAME, GOD_EMAIL, GOD_ABOUT, GOD_PHONE); what is not given is asked.
NAME="${GOD_NAME:-$(ask 'Your full name:')}"
EMAIL="${GOD_EMAIL:-$(ask 'Your work mail address:')}"
ABOUT="${GOD_ABOUT:-$(ask 'What you do, in one line:')}"
PHONE="${GOD_PHONE-$(ask 'Your mobile number in international form, to text God (or leave empty):')}"
[ -n "$NAME" ] && [ -n "$EMAIL" ] || stop "A name and a mail address are needed. Run this again."
ARGS=(--name "$NAME" --email "$EMAIL" --about "$ABOUT")
[ -n "$PHONE" ] && ARGS+=(--phone "$PHONE")
if [ "${GOD_INSTALL_DRY:-}" = "1" ]; then printf '\nWould now run: %s/setup.sh' "$DEST"; printf ' %q' "${ARGS[@]}"; printf '\n'; exit 0; fi
exec bash "$DEST/setup.sh" "${ARGS[@]}" < /dev/tty
