import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

AppletItem {
    id: pillRoot

    property string text: ""
    property string subtitle: ""
    property string iconName: ""
    property var options: []
    property string activeValue: ""
    property bool busy: false
    property bool dimmed: false

    signal selected(string value)

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)
        Layout.bottomMargin: Math.round(Kirigami.Units.smallSpacing / 2)
        spacing: Kirigami.Units.smallSpacing
        opacity: pillRoot.dimmed ? 0.6 : 1.0

        Kirigami.Icon {
            visible: pillRoot.iconName.length > 0
            source: pillRoot.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.sizeForLabels
            Layout.preferredHeight: Kirigami.Units.iconSizes.sizeForLabels
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: pillRoot.text
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: pillRoot.subtitle.length > 0
                text: pillRoot.subtitle
                font: Kirigami.Theme.smallFont
                opacity: 0.65
                elide: Text.ElideRight
            }
        }

        PlasmaComponents3.BusyIndicator {
            visible: pillRoot.busy
            running: pillRoot.busy
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.06
            )
            border.width: 1
            border.color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.12
            )
            implicitWidth: pillsLayout.implicitWidth + 4
            implicitHeight: pillsLayout.implicitHeight + 4

            RowLayout {
                id: pillsLayout
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: pillRoot.options

                    delegate: PlasmaComponents3.ToolButton {
                        id: pillButton
                        required property var modelData
                        readonly property bool isCurrent: String(modelData.value) === pillRoot.activeValue

                        text: String(modelData.label)
                        enabled: !pillRoot.busy
                        checked: isCurrent
                        font.weight: isCurrent ? Font.DemiBold : Font.Normal
                        font.pointSize: Kirigami.Theme.smallFont.pointSize

                        onClicked: {
                            pillRoot.selected(String(pillButton.modelData.value));
                        }
                    }
                }
            }
        }
    }
}
