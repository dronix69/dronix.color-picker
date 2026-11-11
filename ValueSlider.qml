import QtQuick
import qs.Commons
import qs.Commons as Commons
import "ColorMath.js" as ColorMath

Item {
  id: root

  property real value: 100 // 0..100
  property real hue: 0     // 0..360
  property real saturation: 100 // 0..100

  // Full-brightness color at current (hue, saturation, 100)
  readonly property var fullColorRgb: ColorMath.hsvToRgb(hue, saturation, 100)
  readonly property color fullColor: Qt.rgba(fullColorRgb.r / 255, fullColorRgb.g / 255, fullColorRgb.b / 255, 1)

  signal valueChangedLive(real v)

  implicitWidth: Style.space(220)
  implicitHeight: Style.space(26)
  width: implicitWidth
  height: implicitHeight

  readonly property real trackWidth: track.width
  readonly property real trackHeight: Style.space(14)
  readonly property real thumbPosition: track.x + (track.width * (Math.max(0, Math.min(100, value)) / 100))

  function updateFromMouse(mouseX) {
    var relX = mouseX - track.x
    var frac = Math.max(0, Math.min(1, relX / track.width))
    root.value = Math.round(frac * 100)
    root.valueChangedLive(root.value)
  }

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(4)
    anchors.rightMargin: Style.space(4)
    height: root.trackHeight
    radius: Style.cornerRadius
    border.width: 1
    border.color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.3)

    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "#000000" }
      GradientStop { position: 1.0; color: root.fullColor }
    }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onPressed: function(mouse) {
      root.updateFromMouse(mouse.x)
    }

    onPositionChanged: function(mouse) {
      if (pressed) {
        root.updateFromMouse(mouse.x)
      }
    }
  }

  // Thumb knob
  Rectangle {
    id: thumb
    width: Style.space(8)
    height: Style.space(22)
    radius: 3
    color: "#ffffff"
    border.width: 1
    border.color: "#1e1e1e"
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(track.x - width / 2, Math.min(track.x + track.width - width / 2, root.thumbPosition - width / 2))

    // Subtle center notch
    Rectangle {
      anchors.centerIn: parent
      width: 2
      height: 8
      color: "#888888"
      radius: 1
    }
  }
}
