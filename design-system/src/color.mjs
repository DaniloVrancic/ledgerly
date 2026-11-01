// Colour maths for the token build: WCAG contrast, OKLab distance, colour-vision simulation.

export function rgb(hex) {
  const h = hex.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
}

const toLinear = (v) => {
  const c = v / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
};
const fromLinear = (c) => {
  const v = c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055;
  return Math.max(0, Math.min(1, v));
};

export function luminance(hex) {
  const [r, g, b] = rgb(hex).map(toLinear);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrast(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

// Composites a #rrggbbaa colour over an opaque ground.
export function over(fg, bg) {
  if (fg.length !== 9) return fg;
  const a = parseInt(fg.slice(7, 9), 16) / 255;
  const f = rgb(fg);
  const b = rgb(bg);
  const mix = f.map((v, i) => Math.round(v * a + b[i] * (1 - a)));
  return `#${mix.map((v) => v.toString(16).padStart(2, '0')).join('')}`;
}

export function oklab(hex) {
  const [r, g, b] = rgb(hex).map(toLinear);
  return labFromLinear(r, g, b);
}

function labFromLinear(r, g, b) {
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

export function distance(a, b) {
  const x = oklab(a);
  const y = oklab(b);
  return Math.hypot(x[0] - y[0], x[1] - y[1], x[2] - y[2]) * 100;
}

// Machado, Oliveira and Fernandes 2009, severity 1.0.
const CVD = {
  protanopia: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  deuteranopia: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.01182, 0.04294, 0.968881],
  ],
  tritanopia: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.3039],
  ],
};

export function simulate(hex, kind) {
  const lin = rgb(hex).map(toLinear);
  const out = CVD[kind].map((row) => row[0] * lin[0] + row[1] * lin[1] + row[2] * lin[2]);
  return `#${out.map((c) => Math.round(fromLinear(c) * 255).toString(16).padStart(2, '0')).join('')}`;
}

export const CVD_KINDS = Object.keys(CVD);

// Smallest pairwise distance within a set of colours, normally and under each deficiency.
export function separation(colours) {
  const least = (set) => {
    let best = Infinity;
    for (let i = 0; i < set.length; i += 1) {
      for (let j = i + 1; j < set.length; j += 1) best = Math.min(best, distance(set[i], set[j]));
    }
    return best;
  };
  const result = { normal: least(colours) };
  for (const kind of CVD_KINDS) result[kind] = least(colours.map((c) => simulate(c, kind)));
  return result;
}
