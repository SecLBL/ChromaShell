import QtQuick
import qs.config

NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge
    }

    property int type: Anim.Standard

    duration: {
        switch (type) {
        case Anim.StandardSmall:
        case Anim.EmphasizedSmall:
            return Tokens.anim.durations.small;
        case Anim.StandardLarge:
        case Anim.EmphasizedLarge:
            return Tokens.anim.durations.large;
        default:
            return Tokens.anim.durations.normal;
        }
    }
    easing.type: type >= Anim.EmphasizedSmall ? Tokens.anim.emphasized : Tokens.anim.standard
}
