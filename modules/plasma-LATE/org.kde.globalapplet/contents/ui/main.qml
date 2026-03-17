import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    compactRepresentation: Item {
        width: Kirigami.Units.iconSizes.smallMedium
        height: Kirigami.Units.iconSizes.smallMedium

        Kirigami.Icon {
            source: "diag_component"
            active: root.expanded
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.expanded = !root.expanded
        }
    }

    property var nethandlerCheckCMD: `bash -c 'systemctl is-active nethandler.service'`
    property var isNethandlerEnabled: true
    function updateStatus() {
        executable.exec(nethandlerCheckCMD)
    }
    Timer {
        id: updateStatusTimer
        interval: 2000
        repeat: false
        onTriggered: updateStatus()
    }
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source == nethandlerCheckCMD) {
                isNethandlerEnabled = data["stdout"] == "active\n" ? true : false
            }
            disconnectSource(source)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
    }
    fullRepresentation: ScrollView {
        Column {
            spacing: 5
            anchors.fill: parent
            anchors.margins: 10
            // SED_MENU_ITEMS
        }
    }
}

