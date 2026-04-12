import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // IPC handler: qs ipc call maestro showHelp <infoPath> <mapId>
    //              qs ipc call maestro hideHelp
    IpcHandler {
        target: "maestro"

        function showHelp(infoPath: string, mapId: string): void {
            keybindState.loadAndShow(infoPath, mapId);
        }

        function hideHelp(): void {
            keybindState.hide();
        }
    }

    // Global state singleton
    QtObject {
        id: keybindState

        property bool popupVisible: false
        property string currentMapId: ""
        property var keybindsData: null
        property string pendingMapId: ""

        function loadAndShow(infoPath: string, mapId: string): void {
            if (fileView.path !== infoPath) {
                pendingMapId = mapId;
                fileView.path = infoPath;
            } else if (keybindsData !== null) {
                currentMapId = mapId;
                popupVisible = true;
            } else {
                pendingMapId = mapId;
            }
        }

        function hide(): void {
            popupVisible = false;
        }
    }

    FileView {
        id: fileView
        path: ""

        onLoaded: {
            try {
                keybindState.keybindsData = JSON.parse(fileView.text());
                if (keybindState.pendingMapId !== "") {
                    keybindState.currentMapId = keybindState.pendingMapId;
                    keybindState.pendingMapId = "";
                    keybindState.popupVisible = true;
                }
            } catch (e) {
                console.error("Failed to parse keybinds JSON:", e);
            }
        }

        onLoadFailed: (error) => {
            console.error("Failed to load keybinds file:", fileView.path, error);
        }
    }

    FloatingWindow {
        id: helpWindow

        visible: keybindState.popupVisible && keybindState.keybindsData !== null
        title: "Keyboard Shortcuts"
        color: "transparent"

        implicitWidth: contentRect.implicitWidth
        implicitHeight: contentRect.implicitHeight

        Shortcut {
            sequence: "Escape"
            onActivated: keybindState.hide()
        }

        Rectangle {
            id: contentRect
            anchors.fill: parent
            color: "#e61e1e2e"
            border.color: "#585b70"
            border.width: 1
            radius: 12

            implicitWidth: mainLayout.implicitWidth + 48
            implicitHeight: mainLayout.implicitHeight + 48

            ColumnLayout {
                id: mainLayout
                anchors {
                    fill: parent
                    margins: 24
                }
                spacing: 12

                // Title / submap name
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!keybindState.keybindsData) return "";
                        const map = keybindState.keybindsData.maps[keybindState.currentMapId];
                        return (map && map.name) ? map.name : "Keyboard Shortcuts";
                    }
                    font.pixelSize: 14
                    font.bold: true
                    color: "#cdd6f4"
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: "#585b70"
                }

                // Multi-column keybind grid.
                // We split the bind list into N columns and render each as a
                // ColumnLayout so every column independently sizes its badge width.
                RowLayout {
                    id: columnsRow
                    Layout.fillWidth: true
                    spacing: 32

                    // Compute columns and distribute binds
                    property var binds: {
                        if (!keybindState.keybindsData || !keybindState.currentMapId) return [];
                        const map = keybindState.keybindsData.maps[keybindState.currentMapId];
                        return (map && map.binds) ? map.binds : [];
                    }

                    property int numCols: Math.min(Math.max(Math.ceil(Math.sqrt(binds.length)), 1), 4)

                    // Split binds into numCols roughly equal columns (column-major order)
                    property var columns: {
                        const cols = [];
                        const total = binds.length;
                        const n = numCols;
                        const rowsPerCol = Math.ceil(total / n);
                        for (let c = 0; c < n; c++) {
                            cols.push(binds.slice(c * rowsPerCol, (c + 1) * rowsPerCol));
                        }
                        return cols;
                    }

                    Repeater {
                        model: columnsRow.columns

                        // One ColumnLayout per column of binds
                        delegate: ColumnLayout {
                            required property var modelData  // array of bind objects for this column
                            spacing: 6

                            Repeater {
                                model: modelData

                                delegate: RowLayout {
                                    required property var modelData
                                    spacing: 10

                                    // Key chord badge
                                    Rectangle {
                                        implicitWidth: badgeText.implicitWidth + 16
                                        implicitHeight: badgeText.implicitHeight + 8
                                        Layout.alignment: Qt.AlignVCenter
                                        color: "#1e89b4fa"
                                        border.color: "#89b4fa"
                                        border.width: 1
                                        radius: 5

                                        Text {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: {
                                                const mods = modelData.key.modifiers;
                                                const parts = [];
                                                if (mods.super) parts.push("Super");
                                                if (mods.ctrl)  parts.push("Ctrl");
                                                if (mods.alt)   parts.push("Alt");
                                                if (mods.shift) parts.push("Shift");
                                                parts.push(modelData.key.key);
                                                return parts.join("+");
                                            }
                                            font.pixelSize: 12
                                            font.family: "monospace"
                                            font.weight: Font.Medium
                                            color: "#89b4fa"
                                        }
                                    }

                                    // Description
                                    Text {
                                        text: modelData.name || modelData.description || ""
                                        font.pixelSize: 13
                                        color: "#cdd6f4"
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 200
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
