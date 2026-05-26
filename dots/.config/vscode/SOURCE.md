copied from https://github.com/caelestia-dots/caelestia/tree/main/vscode

- settings.json and keybindings.json are shared for both VSCodium (~/.config/VSCodium/User/) and VS Code (~/.config/Code/User/)
- flags.conf is shared for both (codium-flags.conf / code-flags.conf)
- no changes from upstream
- workbench.colorTheme "Caelestia" requires the caelestia-vscode-integration extension (caelestia-vscode-integration-1.2.0.vsix in the upstream repo) — install manually via Extensions → "Install from VSIX"
- the extension reads scheme.json directly and updates the theme live on every caelestia theme change
