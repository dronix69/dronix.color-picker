import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "ColorMath.js" as ColorMath

Panel {
  id: root
  moduleName: "dronix.color-picker"
  ipcTarget: "dronix.color-picker"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  // Active color components (sRGB 0..255 and alpha 0..1)
  property int colorR: 59
  property int colorG: 130
  property int colorB: 246
  property real colorA: 1.0

  // HSV representation for the wheel and slider
  property real hsvH: 217
  property real hsvS: 76
  property real hsvV: 96

  readonly property color currentColor: Qt.rgba(colorR / 255, colorG / 255, colorB / 255, colorA)
  readonly property string currentColorHex: ColorMath.rgbaToHex(colorR, colorG, colorB, colorA)
  property string copiedFormatId: ""

  property var recentColors: [
    "#ef4444", "#f97316", "#f59e0b", "#10b981", "#06b6d4",
    "#3b82f6", "#6366f1", "#8b5cf6", "#ec4899", "#f43f5e"
  ]

  readonly property var formatList: ColorMath.formatAll(colorR, colorG, colorB, colorA)

  function setColor(r, g, b, a, updateHsv) {
    colorR = Math.round(ColorMath.clamp(r, 0, 255))
    colorG = Math.round(ColorMath.clamp(g, 0, 255))
    colorB = Math.round(ColorMath.clamp(b, 0, 255))
    colorA = a !== undefined ? Math.round(ColorMath.clamp(a, 0, 1) * 100) / 100 : 1.0

    if (updateHsv !== false) {
      var hsv = ColorMath.rgbaToHsv(colorR, colorG, colorB, colorA)
      hsvH = hsv.h
      hsvS = hsv.s
      hsvV = hsv.v
    }

    var hex = ColorMath.rgbaToHex(colorR, colorG, colorB, colorA)
    if (!hexInput.activeFocus) {
      hexInput.text = hex
    }
  }

  function setFromHsv(h, s, v) {
    hsvH = h
    hsvS = s
    hsvV = v
    var rgb = ColorMath.hsvToRgb(h, s, v)
    setColor(rgb.r, rgb.g, rgb.b, colorA, false)
  }

  function setColorFromInput(text) {
    var parsed = ColorMath.parseColor(text)
    if (parsed) {
      setColor(parsed.r, parsed.g, parsed.b, parsed.a, true)
      addRecentColor(ColorMath.rgbaToHex(parsed.r, parsed.g, parsed.b, parsed.a))
      return true
    }
    return false
  }

  function addRecentColor(hex) {
    var list = recentColors.slice()
    var idx = list.indexOf(hex)
    if (idx !== -1) list.splice(idx, 1)
    list.unshift(hex)
    if (list.length > 10) list.pop()
    recentColors = list
  }

  function copyValue(formatId, text) {
    Quickshell.execDetached(["wl-copy", "--", text])
    copiedFormatId = formatId
    copyTimer.restart()
  }

  function pickScreenColor() {
    if (pickerProc.running) return
    pickerProc.running = true
  }

  function formatValueForDefault(formatId) {
    for (var i = 0; i < formatList.length; i++) {
      if (formatList[i].name === formatId || formatList[i].id === formatId) {
        return formatList[i].value
      }
    }
    return currentColorHex
  }

  Timer {
    id: copyTimer
    interval: 1500
    onTriggered: root.copiedFormatId = ""
  }

  Process {
    id: pickerProc
    command: ["hyprpicker", "-f", "hex", "-l"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: function() {
        var str = text ? text.trim() : ""
        if (str && str.length > 0) {
          root.setColorFromInput(str)
          var autoCopy = root.setting("copyOnPick", true)
          if (autoCopy) {
            var targetFormat = root.setting("defaultFormat", "HEX")
            var valToCopy = root.formatValueForDefault(targetFormat)
            root.copyValue(targetFormat.toLowerCase(), valToCopy)
          }
        }
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏘"
    active: true
    useActiveColor: true
    activeColor: root.currentColor
    tooltipText: strings.t("plugin.name") + ": " + root.currentColorHex

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.pickScreenColor()
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(mainLayout.implicitHeight, Style.space(780))

    onOpenChanged: {
      if (open) {
        Qt.callLater(function() {
          if (colorWheel) colorWheel.repaint()
        })
      }
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      implicitHeight: mainLayout.implicitHeight
      blocked: hexInput.activeFocus
      onCloseRequested: root.close()

      ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(10)

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: strings.t("plugin.name")
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            color: Commons.Color.foreground
            Layout.fillWidth: true
          }

          Button {
            text: strings.t("button.pick")
            iconText: "󰈊"
            bordered: true
            fontSize: Style.font.bodySmall
            onClicked: root.pickScreenColor()
          }
        }

        // Active Color Swatch & Manual Input
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)

          Rectangle {
            Layout.preferredWidth: Style.space(44)
            Layout.preferredHeight: Style.space(34)
            radius: Style.cornerRadius
            color: root.currentColor
            border.width: 1
            border.color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.25)
          }

          TextField {
            id: hexInput
            Layout.fillWidth: true
            placeholderText: strings.t("label.input")
            text: root.currentColorHex
            onTextEdited: root.setColorFromInput(text)
            onAccepted: root.setColorFromInput(text)
          }
        }

        // Interactive Color Wheel and Brightness Slider
        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          spacing: Style.space(8)

          ColorWheel {
            id: colorWheel
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.space(190)
            Layout.preferredHeight: Style.space(190)
            hue: root.hsvH
            saturation: root.hsvS
            value: root.hsvV

            onColorPicked: function(h, s, v) {
              root.setFromHsv(h, s, v)
            }
          }

          ValueSlider {
            id: valueSlider
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.space(220)
            Layout.preferredHeight: Style.space(26)
            hue: root.hsvH
            saturation: root.hsvS
            value: root.hsvV

            onValueChangedLive: function(v) {
              root.setFromHsv(root.hsvH, root.hsvS, v)
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
        }

        // Formats section
        PanelSectionHeader {
          text: strings.t("label.formats")
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(5)

          Repeater {
            model: root.formatList
            delegate: BorderSurface {
              id: rowSurface
              required property var modelData
              required property int index

              Layout.fillWidth: true
              implicitHeight: Style.space(34)
              radius: Style.cornerRadius
              borderSpec: Border.controlSpec(rowMouse.containsMouse ? "hover-cursor" : "normal", Commons.Color.foreground, Commons.Color.accent)
              color: Style.controlFill(false, rowMouse.containsMouse, Commons.Color.foreground, Commons.Color.accent)

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyValue(modelData.id, modelData.value)
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(8)

                Rectangle {
                  Layout.preferredWidth: Style.space(58)
                  Layout.preferredHeight: Style.space(22)
                  radius: Math.max(2, Style.cornerRadius - 2)
                  color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.08)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: modelData.name
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: Commons.Color.foreground
                  }
                }

                Text {
                  Layout.fillWidth: true
                  textFormat: Text.PlainText
                  text: modelData.value
                  font.family: Style.font.family
                  font.pixelSize: Style.font.body
                  color: Commons.Color.foreground
                  elide: Text.ElideRight
                }

                Button {
                  Layout.preferredHeight: Style.space(26)
                  fontSize: Style.font.caption
                  text: root.copiedFormatId === modelData.id ? strings.t("button.copied") : strings.t("button.copy")
                  iconText: root.copiedFormatId === modelData.id ? "✓" : "󰆏"
                  bordered: true
                  active: root.copiedFormatId === modelData.id
                  onClicked: root.copyValue(modelData.id, modelData.value)
                }
              }
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
        }

        // Recent colors palette
        PanelSectionHeader {
          text: strings.t("label.recent")
        }

        Flow {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Repeater {
            model: root.recentColors
            delegate: Rectangle {
              id: swatchRect
              required property string modelData
              required property int index

              width: Style.space(28)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: modelData
              border.width: 1
              border.color: swatchMouse.containsMouse ? Commons.Color.accent : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.2)

              scale: swatchMouse.containsMouse ? 1.15 : 1.0
              Behavior on scale {
                NumberAnimation { duration: Style.duration(120); easing.type: Easing.OutCubic }
              }

              MouseArea {
                id: swatchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setColorFromInput(modelData)
              }
            }
          }
        }
      }
    }
  }
}
