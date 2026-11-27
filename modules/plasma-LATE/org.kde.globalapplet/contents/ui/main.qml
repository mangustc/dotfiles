import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
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
    component MenuItem: PlasmaComponents3.ItemDelegate {
        signal triggered()
        Layout.fillWidth: true
        onClicked: triggered()
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep

        readonly property real desiredHeight: (plasmoidHeading.visible ? plasmoidHeading.implicitHeight : 0)
            + menuColumn.implicitHeight
            + Kirigami.Units.largeSpacing * 2

        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Math.min(
            Kirigami.Units.gridUnit * 24,
            Math.max(Kirigami.Units.gridUnit * 12, desiredHeight)
        )
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            id: plasmoidHeading
            visible: !(Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.Heading {
                    Layout.fillWidth: true
                    level: 1
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: Plasmoid.title
                }
            }
        }

        contentItem: PlasmaComponents3.ScrollView {
            id: scrollView
            PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

            contentItem: Flickable {
                id: flickable
                contentWidth: width
                contentHeight: menuColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: menuColumn
                    x: Kirigami.Units.largeSpacing
                    y: Kirigami.Units.largeSpacing
                    width: Math.max(0, flickable.width - Kirigami.Units.largeSpacing * 2)
                    spacing: Kirigami.Units.smallSpacing

                    // SED_MENU_ITEMS
                }
            }
        }
    }
}

