import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: itemRoot

    property var applet: null
    property string section: ""
    property bool shown: true

    signal refresh()

    Layout.fillWidth: true
    spacing: 0

    function exec(cmd, callback) {
        if (itemRoot.applet) {
            itemRoot.applet.exec(cmd, callback);
        }
    }

    function closePopup() {
        if (itemRoot.applet) {
            itemRoot.applet.expanded = false;
        }
    }

    onAppletChanged: {
        if (itemRoot.applet) {
            Qt.callLater(() => itemRoot.refresh());
        }
    }

    Connections {
        target: itemRoot.applet ?? null
        ignoreUnknownSignals: true

        function onRefreshRequested() {
            itemRoot.refresh();
        }
    }
}
