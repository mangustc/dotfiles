import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    signal refreshRequested()

    readonly property var registeredItems: [
        // SED_MENU_ITEMS
    ]

    function exec(cmd, callback) {
        commandRunner.exec(cmd, callback);
    }

    function attachApplet(itemObj) {
        if (itemObj && ("applet" in itemObj)) {
            itemObj.applet = root;
        }
    }

    function readItemSection(itemObj) {
        if (itemObj && itemObj.section !== undefined) {
            return String(itemObj.section);
        }
        return "";
    }

    function readItemShown(itemObj) {
        if (!itemObj) {
            return false;
        }
        if (itemObj.shown !== undefined) {
            return Boolean(itemObj.shown);
        }
        return true;
    }

    onExpandedChanged: {
        if (root.expanded) {
            root.refreshRequested();
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh-symbolic"
            onTriggered: root.refreshRequested()
        }
    ]

    CommandRunner {
        id: commandRunner
    }

    Plasmoid.icon: "diag_component-symbolic"

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        Kirigami.Icon {
            anchors.fill: parent
            source: "diag_component-symbolic"
            active: mouseArea.containsMouse || root.expanded
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep

        readonly property real desiredHeight: (plasmoidHeading.visible ? plasmoidHeading.implicitHeight : 0)
            + menuColumn.implicitHeight
            + Kirigami.Units.largeSpacing * 2

        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Math.min(
            Kirigami.Units.gridUnit * 26,
            Math.max(Kirigami.Units.gridUnit * 10, desiredHeight)
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

                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh-symbolic"
                    onClicked: root.refreshRequested()

                    PlasmaComponents3.ToolTip {
                        text: "Refresh"
                    }
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

                    property var itemStates: ({})

                    function setItemState(idx, vis, sec) {
                        const prev = menuColumn.itemStates[idx];
                        if (prev && prev.visible === vis && prev.section === sec) {
                            return;
                        }
                        const next = Object.assign({}, menuColumn.itemStates);
                        next[idx] = { visible: vis, section: sec };
                        menuColumn.itemStates = next;
                    }

                    function prevVisibleSectionFor(idx, states) {
                        for (let i = idx - 1; i >= 0; --i) {
                            const st = states[i];
                            if (st && st.visible) {
                                return st.section;
                            }
                        }
                        return null;
                    }

                    Repeater {
                        id: itemsRepeater
                        model: root.registeredItems

                        delegate: ColumnLayout {
                            id: itemWrapper
                            required property int index
                            required property string modelData

                            readonly property AppletItem appletItem: itemLoader.item as AppletItem
                            readonly property bool itemVisible: itemLoader.status === Loader.Ready
                                && itemLoader.item !== null
                                && (appletItem ? appletItem.shown : root.readItemShown(itemLoader.item))
                            readonly property string itemSection: appletItem
                                ? appletItem.section
                                : root.readItemSection(itemLoader.item)
                            readonly property var prevSection: menuColumn.prevVisibleSectionFor(
                                itemWrapper.index,
                                menuColumn.itemStates
                            )

                            onItemVisibleChanged: menuColumn.setItemState(
                                itemWrapper.index,
                                itemWrapper.itemVisible,
                                itemWrapper.itemSection
                            )
                            onItemSectionChanged: menuColumn.setItemState(
                                itemWrapper.index,
                                itemWrapper.itemVisible,
                                itemWrapper.itemSection
                            )
                            Component.onCompleted: menuColumn.setItemState(
                                itemWrapper.index,
                                itemWrapper.itemVisible,
                                itemWrapper.itemSection
                            )

                            visible: itemWrapper.itemVisible
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Separator {
                                Layout.fillWidth: true
                                Layout.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                                visible: itemWrapper.prevSection !== null
                                    && itemWrapper.itemSection !== itemWrapper.prevSection
                            }

                            Kirigami.Heading {
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                level: 5
                                opacity: 0.65
                                text: itemWrapper.itemSection
                                visible: itemWrapper.itemSection.length > 0
                                    && itemWrapper.itemSection !== itemWrapper.prevSection
                            }

                            Loader {
                                id: itemLoader
                                Layout.fillWidth: true
                                source: Qt.resolvedUrl(itemWrapper.modelData)
                                onLoaded: root.attachApplet(itemLoader.item)
                            }
                        }
                    }
                }
            }
        }
    }
}
