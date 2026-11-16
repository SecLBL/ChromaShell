# ToDo

## Audio level meters

Live peak/RMS meter (OBS-style, monochrome, with marked loud/clipping zones) next to volume sliders.

- Needs new C++ in the shell plugin (`Caelestia.Services`): a QML element per meter that opens a passive PipeWire capture stream on a node (`target.object`, `stream.capture.sink` for sink monitors) and exposes peak/RMS in dBFS at ~30 Hz.
- Passive stream so a visible meter doesn't wake suspended chains.
- Use in: Recording & replay → audio tracks, and the normal Audio settings page (buses, mic).
