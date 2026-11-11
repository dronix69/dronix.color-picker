import QtQuick
import qs.Commons
import qs.Commons as Commons
import "ColorMath.js" as ColorMath

Item {
  id: root

  property real hue: 217        // 0..360
  property real saturation: 76  // 0..100
  property real value: 96       // 0..100

  readonly property var rgbObj: ColorMath.hsvToRgb(hue, saturation, value)
  readonly property color currentColor: Qt.rgba(rgbObj.r / 255, rgbObj.g / 255, rgbObj.b / 255, 1.0)

  signal colorPicked(real h, real s, real v)

  implicitWidth: Style.space(190)
  implicitHeight: Style.space(190)
  width: implicitWidth
  height: implicitHeight

  readonly property real radius: Math.min(width, height) / 2 - Style.space(4)
  readonly property real centerX: width / 2
  readonly property real centerY: height / 2

  // Handle position
  readonly property real handleDistance: radius * (saturation / 100)
  readonly property real handleAngleRad: (hue * Math.PI) / 180
  readonly property real handleX: centerX + handleDistance * Math.cos(handleAngleRad)
  readonly property real handleY: centerY + handleDistance * Math.sin(handleAngleRad)

  function repaint() {
    wheelCanvas.requestPaint()
  }

  function updateFromPosition(mouseX, mouseY) {
    var dx = mouseX - centerX
    var dy = mouseY - centerY
    var dist = Math.sqrt(dx * dx + dy * dy)
    var sat = Math.max(0, Math.min(100, (dist / radius) * 100))

    var rad = Math.atan2(dy, dx)
    var deg = (rad * 180) / Math.PI
    if (deg < 0) deg += 360

    root.hue = deg
    root.saturation = sat
    root.colorPicked(root.hue, root.saturation, root.value)
  }

  onWidthChanged: wheelCanvas.requestPaint()
  onHeightChanged: wheelCanvas.requestPaint()

  Component.onCompleted: {
    wheelCanvas.requestPaint()
  }

  Canvas {
    id: wheelCanvas
    anchors.fill: parent
    renderStrategy: Canvas.Cooperative
    antialiasing: true

    onAvailableChanged: if (available) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cx = root.centerX
      var cy = root.centerY
      var r = root.radius
      if (r <= 0) return

      var step = 1.5
      for (var deg = 0; deg < 360; deg += step) {
        var startAngle = (deg - 0.8) * Math.PI / 180
        var endAngle = (deg + step + 0.8) * Math.PI / 180

        var edgeColor = Qt.hsla(deg / 360, 1.0, 0.5, 1.0)
        var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
        grad.addColorStop(0, "#ffffff")
        grad.addColorStop(1, edgeColor)

        ctx.beginPath()
        ctx.moveTo(cx, cy)
        ctx.arc(cx, cy, r, startAngle, endAngle)
        ctx.closePath()
        ctx.fillStyle = grad
        ctx.fill()
      }

      // Outer border circle
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.strokeStyle = "rgba(0, 0, 0, 0.25)"
      ctx.lineWidth = 1
      ctx.stroke()
    }
  }

  MouseArea {
    id: wheelMouse
    anchors.fill: parent
    cursorShape: Qt.CrossCursor

    onPressed: function(mouse) {
      root.updateFromPosition(mouse.x, mouse.y)
    }

    onPositionChanged: function(mouse) {
      if (pressed) {
        root.updateFromPosition(mouse.x, mouse.y)
      }
    }
  }

  // Handle on wheel
  Item {
    id: handleItem
    x: root.handleX - width / 2
    y: root.handleY - height / 2
    width: Style.space(22)
    height: Style.space(22)

    // Outer dark shadow ring
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      border.width: 3
      border.color: "#000000"
    }

    // Inner bright ring with current color fill
    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: width / 2
      color: root.currentColor
      border.width: 2
      border.color: "#ffffff"
    }
  }
}
