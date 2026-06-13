# ChromaShell

My personal Hyprland dotfiles. This is a Wayland desktop setup built on top of
[Caelestia](https://github.com/caelestia-dots) — it leans heavily on the
Caelestia shell and CLI, so most of what makes this desktop tick isn't actually
my code.

The `dots/` directory mirrors `~/.config/` and holds the configs for Hyprland,
Kitty, Fish, Starship, the audio pipeline, and the usual smaller bits (btop,
fastfetch, spicetify, and so on).

I originally started this because I wanted a fast way to get a working desktop
back up after my main setup broke (again), without crawling through config
guides every time. Nothing out there quite matched what I wanted, so this turned
into my own thing.

## What's in here

On top of the plain configs, a few things I'm happy with — all of it lives in
this repo, the flake just deploys it:

- **A DAW-ish audio setup** — three PipeWire loopbacks (chat, desktop, mic)
  feeding three independent filter chains (EQ, gate, compressor, and DeepFilterNet
  noise suppression), all controllable from Caelestia's Nexus settings UI.
- **Pywal theming on top of Caelestia's** — an extra dynamic theming layer for
  more varied color schemes alongside Caelestia's own.
- **A tiny local color server** — a small SSE service that hands out the current
  colors, working around Nix store immutability so dynamic theming actually
  reaches places it normally can't. Two things ride on it: **ChromaFox**, a
  Firefox extension that themes the browser (and, via DarkReader, the websites
  you visit) live, and a Spicetify extension that does the same for Spotify.
- **A layered Hyprland config** — the ChromaShell defaults live in `config/`,
  with a separate `custom/` directory for your own keybinds, rules and tweaks on
  top, so you never have to edit the base to make it yours. The layered approach
  is inspired by End-4's setup.
- **Smaller extras** — blur effects, a media mini-player, and a pile of little
  tweaks and fixes.

The flake (below) adds the app-picking part on top: choose your browser, chat
app, music app and editor, and it installs them and wires them into the theming
and keybinds. Through all of this, Caelestia's shell and CLI stay fully
functional — this extends them, it doesn't replace them.

## Heads up: this repo on its own won't give you a working system

These are just dotfiles. They expect a bunch of packages, the Caelestia
shell/CLI, theming, and activation logic that live elsewhere. If you clone this
and symlink it into place, things will be broken.

So there are two ways to use this:

- **For inspiration / cherry-picking** — read through the configs, copy the
  parts you like into your own setup. That's totally fine and probably the most
  useful thing here for most people.
- **To actually run it** — use the companion Home Manager flake:
  **https://github.com/SecLBL/ChromaShell-Flake**. That repo pulls these
  dotfiles in, installs the packages, wires up the shell and theming, and
  symlinks everything into the right place. It's the only supported way to get
  the whole thing running.

## Credits

This wouldn't exist without:

- **[Caelestia](https://github.com/caelestia-dots)** — ChromaShell is basically
  built around their shell and CLI. The vast majority of the credit goes here.
  Huge thanks.
- **End-4 / [illogical-impulse](https://github.com/end-4/dots-hyprland)** — for
  the ideas and inspiration that got me into this whole rabbit hole in the first
  place.
