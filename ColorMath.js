.pragma library

// Color conversion and formatting functions for dronix.color-picker

function clamp(val, min, max) {
  return Math.max(min, Math.min(max, val));
}

function toHexByte(n) {
  return clamp(Math.round(n), 0, 255).toString(16).padStart(2, "0");
}

function rgbaToHex(r, g, b, a) {
  var alpha = a !== undefined ? clamp(a, 0, 1) : 1;
  if (alpha < 0.999) {
    return "#" + toHexByte(r) + toHexByte(g) + toHexByte(b) + toHexByte(alpha * 255);
  }
  return "#" + toHexByte(r) + toHexByte(g) + toHexByte(b);
}

function rgbaToRgb(r, g, b) {
  return "rgb(" + Math.round(clamp(r, 0, 255)) + ", " + Math.round(clamp(g, 0, 255)) + ", " + Math.round(clamp(b, 0, 255)) + ")";
}

function rgbaToRgba(r, g, b, a) {
  var alpha = a !== undefined ? Math.round(clamp(a, 0, 1) * 100) / 100 : 1;
  return "rgba(" + Math.round(clamp(r, 0, 255)) + ", " + Math.round(clamp(g, 0, 255)) + ", " + Math.round(clamp(b, 0, 255)) + ", " + alpha + ")";
}

function rgbaToHsl(r, g, b, a) {
  var rn = clamp(r, 0, 255) / 255;
  var gn = clamp(g, 0, 255) / 255;
  var bn = clamp(b, 0, 255) / 255;
  var max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
  var h = 0, s = 0, l = (max + min) / 2;
  if (max !== min) {
    var d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case rn: h = (gn - bn) / d + (gn < bn ? 6 : 0); break;
      case gn: h = (bn - rn) / d + 2; break;
      case bn: h = (rn - gn) / d + 4; break;
    }
    h *= 60;
  }
  h = Math.round(h);
  s = Math.round(s * 100);
  l = Math.round(l * 100);
  var alpha = a !== undefined ? Math.round(clamp(a, 0, 1) * 100) / 100 : 1;
  var str = alpha < 0.999
    ? "hsla(" + h + ", " + s + "%, " + l + "%, " + alpha + ")"
    : "hsl(" + h + ", " + s + "%, " + l + "%)";
  return { h: h, s: s, l: l, a: alpha, string: str };
}

function rgbaToHsv(r, g, b, a) {
  var rn = clamp(r, 0, 255) / 255;
  var gn = clamp(g, 0, 255) / 255;
  var bn = clamp(b, 0, 255) / 255;
  var max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
  var h = 0, s = 0, v = max;
  var d = max - min;
  s = max === 0 ? 0 : d / max;
  if (max !== min) {
    switch (max) {
      case rn: h = (gn - bn) / d + (gn < bn ? 6 : 0); break;
      case gn: h = (bn - rn) / d + 2; break;
      case bn: h = (rn - gn) / d + 4; break;
    }
    h *= 60;
  }
  h = Math.round(h);
  s = Math.round(s * 100);
  v = Math.round(v * 100);
  var alpha = a !== undefined ? Math.round(clamp(a, 0, 1) * 100) / 100 : 1;
  var str = "hsv(" + h + ", " + s + "%, " + v + "%)";
  return { h: h, s: s, v: v, a: alpha, string: str };
}

function rgbaToOklch(r, g, b, a) {
  function toLin(c) {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  }
  var rLin = toLin(clamp(r, 0, 255) / 255);
  var gLin = toLin(clamp(g, 0, 255) / 255);
  var bLin = toLin(clamp(b, 0, 255) / 255);

  var l = 0.4122214708 * rLin + 0.5363325363 * gLin + 0.0514459929 * bLin;
  var m = 0.2119034982 * rLin + 0.6806995451 * gLin + 0.1073969566 * bLin;
  var s = 0.0883024619 * rLin + 0.2817188376 * gLin + 0.6299787005 * bLin;

  var l_ = Math.cbrt(l);
  var m_ = Math.cbrt(m);
  var s_ = Math.cbrt(s);

  var L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
  var a_val = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
  var b_val = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

  var C = Math.sqrt(a_val * a_val + b_val * b_val);
  var H = Math.atan2(b_val, a_val) * (180 / Math.PI);
  if (H < 0) H += 360;

  var L_rounded = Math.round(L * 1000) / 1000;
  var C_rounded = Math.round(C * 1000) / 1000;
  var H_rounded = Math.round(H * 10) / 10;
  var alpha = a !== undefined ? Math.round(clamp(a, 0, 1) * 100) / 100 : 1;

  var str = alpha < 0.999
    ? "oklch(" + L_rounded + " " + C_rounded + " " + H_rounded + " / " + alpha + ")"
    : "oklch(" + L_rounded + " " + C_rounded + " " + H_rounded + ")";

  return { l: L_rounded, c: C_rounded, h: H_rounded, a: alpha, string: str };
}

function oklchToRgb(L, C, H) {
  var hRad = (H * Math.PI) / 180;
  var a_val = C * Math.cos(hRad);
  var b_val = C * Math.sin(hRad);

  var l_ = L + 0.3963377774 * a_val + 0.2158037573 * b_val;
  var m_ = L - 0.1055613458 * a_val - 0.0638541728 * b_val;
  var s_ = L - 0.0894841775 * a_val - 1.2914855480 * b_val;

  var l = l_ * l_ * l_;
  var m = m_ * m_ * m_;
  var s = s_ * s_ * s_;

  var rLin = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  var gLin = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  var bLin = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

  function toGamma(c) {
    c = clamp(c, 0, 1);
    return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  }

  return {
    r: Math.round(toGamma(rLin) * 255),
    g: Math.round(toGamma(gLin) * 255),
    b: Math.round(toGamma(bLin) * 255)
  };
}

function hslToRgb(h, s, l) {
  h = ((h % 360) + 360) % 360;
  s = clamp(s, 0, 100) / 100;
  l = clamp(l, 0, 100) / 100;
  var c = (1 - Math.abs(2 * l - 1)) * s;
  var x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  var m = l - c / 2;
  var r = 0, g = 0, b = 0;
  if (0 <= h && h < 60) { r = c; g = x; b = 0; }
  else if (60 <= h && h < 120) { r = x; g = c; b = 0; }
  else if (120 <= h && h < 180) { r = 0; g = c; b = x; }
  else if (180 <= h && h < 240) { r = 0; g = x; b = c; }
  else if (240 <= h && h < 300) { r = x; g = 0; b = c; }
  else if (300 <= h && h < 360) { r = c; g = 0; b = x; }
  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255)
  };
}

function hsvToRgb(h, s, v) {
  h = ((h % 360) + 360) % 360;
  s = clamp(s, 0, 100) / 100;
  v = clamp(v, 0, 100) / 100;
  var c = v * s;
  var x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  var m = v - c;
  var r = 0, g = 0, b = 0;
  if (0 <= h && h < 60) { r = c; g = x; b = 0; }
  else if (60 <= h && h < 120) { r = x; g = c; b = 0; }
  else if (120 <= h && h < 180) { r = 0; g = c; b = x; }
  else if (180 <= h && h < 240) { r = 0; g = x; b = c; }
  else if (240 <= h && h < 300) { r = x; g = 0; b = c; }
  else if (300 <= h && h < 360) { r = c; g = 0; b = x; }
  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255)
  };
}

function parseColor(input) {
  if (!input || typeof input !== "string") return null;
  var s = input.trim().toLowerCase();

  // Hex (#rgb, #rgba, #rrggbb, #rrggbbaa, or without #)
  var hexMatch = s.match(/^#?([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/);
  if (hexMatch) {
    var raw = hexMatch[1];
    if (raw.length === 3 || raw.length === 4) {
      raw = raw.split("").map(function(c) { return c + c; }).join("");
    }
    if (raw.length === 6) {
      return {
        r: parseInt(raw.substring(0, 2), 16),
        g: parseInt(raw.substring(2, 4), 16),
        b: parseInt(raw.substring(4, 6), 16),
        a: 1
      };
    } else if (raw.length === 8) {
      return {
        r: parseInt(raw.substring(0, 2), 16),
        g: parseInt(raw.substring(2, 4), 16),
        b: parseInt(raw.substring(4, 6), 16),
        a: Math.round((parseInt(raw.substring(6, 8), 16) / 255) * 100) / 100
      };
    }
  }

  // RGB / RGBA
  var rgbMatch = s.match(/^rgba?\(\s*([0-9.]+)[,\s]+([0-9.]+)[,\s]+([0-9.]+)(?:[,\s/]+([0-9.]+%?))?\s*\)$/);
  if (rgbMatch) {
    var r = clamp(parseFloat(rgbMatch[1]), 0, 255);
    var g = clamp(parseFloat(rgbMatch[2]), 0, 255);
    var b = clamp(parseFloat(rgbMatch[3]), 0, 255);
    var a = 1;
    if (rgbMatch[4]) {
      var aStr = rgbMatch[4];
      a = aStr.endsWith("%") ? parseFloat(aStr) / 100 : parseFloat(aStr);
      a = clamp(a, 0, 1);
    }
    return { r: Math.round(r), g: Math.round(g), b: Math.round(b), a: Math.round(a * 100) / 100 };
  }

  // HSL / HSLA
  var hslMatch = s.match(/^hsla?\(\s*([0-9.]+)[,\s]+([0-9.]+)%?[,\s]+([0-9.]+)%?(?:[,\s/]+([0-9.]+%?))?\s*\)$/);
  if (hslMatch) {
    var h = parseFloat(hslMatch[1]);
    var sl = parseFloat(hslMatch[2]);
    var l = parseFloat(hslMatch[3]);
    var a = 1;
    if (hslMatch[4]) {
      var aStr = hslMatch[4];
      a = aStr.endsWith("%") ? parseFloat(aStr) / 100 : parseFloat(aStr);
      a = clamp(a, 0, 1);
    }
    var rgbHsl = hslToRgb(h, sl, l);
    rgbHsl.a = Math.round(a * 100) / 100;
    return rgbHsl;
  }

  // HSV
  var hsvMatch = s.match(/^hsv\(\s*([0-9.]+)[,\s]+([0-9.]+)%?[,\s]+([0-9.]+)%?(?:[,\s/]+([0-9.]+%?))?\s*\)$/);
  if (hsvMatch) {
    var hHsv = parseFloat(hsvMatch[1]);
    var sVal = parseFloat(hsvMatch[2]);
    var vVal = parseFloat(hsvMatch[3]);
    var aHsv = 1;
    if (hsvMatch[4]) {
      var aStrHsv = hsvMatch[4];
      aHsv = aStrHsv.endsWith("%") ? parseFloat(aStrHsv) / 100 : parseFloat(aStrHsv);
      aHsv = clamp(aHsv, 0, 1);
    }
    var rgbHsv = hsvToRgb(hHsv, sVal, vVal);
    rgbHsv.a = Math.round(aHsv * 100) / 100;
    return rgbHsv;
  }

  // OKLCH
  var oklchMatch = s.match(/^oklch\(\s*([0-9.]+%?)[,\s]+([0-9.]+)[,\s]+([0-9.]+)(?:[,\s/]+([0-9.]+%?))?\s*\)$/);
  if (oklchMatch) {
    var L = oklchMatch[1].endsWith("%") ? parseFloat(oklchMatch[1]) / 100 : parseFloat(oklchMatch[1]);
    var C = parseFloat(oklchMatch[2]);
    var H = parseFloat(oklchMatch[3]);
    var aOklch = 1;
    if (oklchMatch[4]) {
      var aStrOklch = oklchMatch[4];
      aOklch = aStrOklch.endsWith("%") ? parseFloat(aStrOklch) / 100 : parseFloat(aStrOklch);
      aOklch = clamp(aOklch, 0, 1);
    }
    var rgbOklch = oklchToRgb(L, C, H);
    rgbOklch.a = Math.round(aOklch * 100) / 100;
    return rgbOklch;
  }

  return null;
}

function formatAll(r, g, b, a) {
  return [
    { id: "hex", name: "HEX", value: rgbaToHex(r, g, b, a) },
    { id: "rgb", name: "RGB", value: rgbaToRgb(r, g, b) },
    { id: "rgba", name: "RGBA", value: rgbaToRgba(r, g, b, a) },
    { id: "hsl", name: "HSL", value: rgbaToHsl(r, g, b, a).string },
    { id: "hsv", name: "HSV", value: rgbaToHsv(r, g, b, a).string },
    { id: "oklch", name: "OKLCH", value: rgbaToOklch(r, g, b, a).string }
  ];
}
