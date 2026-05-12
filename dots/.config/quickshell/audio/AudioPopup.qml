// ChromaShell — Audio Control Popup
//
// Sektionen (geplant):
//
// 1. Bus-Lautstärken
//    ├── MixBus        (volume-control.sh mixbus)
//    ├── MixBus Chat   (volume-control.sh mixbus-chat)
//    └── Virtual Cable (volume-control.sh cable)
//
// 2. Mic Chain
//    ├── Gate
//    │   ├── Threshold  (audio-param.sh mic-gate gt)
//    │   ├── Attack     (audio-param.sh mic-gate at)
//    │   ├── Release    (audio-param.sh mic-gate rt)
//    │   ├── Hold       (audio-param.sh mic-gate hold)
//    │   └── Reduction  (audio-param.sh mic-gate gr)
//    ├── Noise Repellent
//    │   └── Amount     (audio-param.sh mic-nr nres)
//    └── Compressor
//        ├── Threshold  (audio-param.sh mic-comp al)
//        ├── Ratio      (audio-param.sh mic-comp cr)
//        ├── Attack     (audio-param.sh mic-comp at)
//        ├── Release    (audio-param.sh mic-comp rt)
//        └── Knee       (audio-param.sh mic-comp kn)
//
// 3. Chat Chain
//    ├── Noise Repellent (audio-param.sh chat-nr nres)
//    └── Compressor      (audio-param.sh chat-comp *)
//
// Alle Slider rufen via Process { command: ["audio-param.sh", ...] } auf

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    // TODO
}
