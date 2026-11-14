globalThis.PanoramaField = (() => {
  'use strict';

  // The Northern Dipper as the app's speed card draws it: true relative positions, one unit wide, y down, from Alkaid
  // at the tip of the handle round to Dubhe at the lip of the bowl, each with its visual magnitude.
  const DIPPER = [
    [0.0, 0.4803, 1.86],
    [0.2042, 0.2957, 2.04],
    [0.3798, 0.2822, 1.77],
    [0.5938, 0.2478, 3.31],
    [0.7254, 0.3722, 2.44],
    [1.0, 0.2062, 2.37],
    [0.9266, 0.0, 1.79],
  ];
  const DIPPER_LINKS = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3]];
  const MANSIONS = 28;
  const PIXEL_BUDGET = 12e6;
  const LIGHT_STEP = 0.32;
  const LIGHT_HOLD = 6.5;

  const clamp = (value, low, high) => Math.min(high, Math.max(low, value));
  const ease = (t) => 1 - Math.pow(1 - clamp(t, 0, 1), 3);

  // A fixed seed keeps the sky the same on every visit and every resize.
  function random(seed) {
    let s = seed >>> 0;
    return () => {
      s = (s + 0x6d2b79f5) >>> 0;
      let t = s;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // `avoid` and `stage` report boxes in the canvas's own coordinates.
  function mount(canvas, { avoid = () => [], stage = () => null, still = () => false } = {}) {
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;

    let width = 0;
    let height = 0;
    let stars = [];
    let dipper = null;
    let colors = {};
    let frame = 0;
    let started = 0;
    let surgeAt = -Infinity;
    let onScreen = true;
    let pointer = null;

    function measure() {
      const box = canvas.getBoundingClientRect();
      width = box.width;
      height = box.height;
      const ratio = Math.min(devicePixelRatio || 1, 2, Math.sqrt(PIXEL_BUDGET / Math.max(width * height, 1)));
      canvas.width = Math.round(width * ratio);
      canvas.height = Math.round(height * ratio);
      ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    }

    function chart() {
      const margin = 14;
      const blocks = avoid().map((rect) => ({
        left: rect.left - margin,
        right: rect.right + margin,
        top: rect.top - margin,
        bottom: rect.bottom + margin,
      }));
      const next = random(20261114);
      const count = Math.round(clamp((width * height) / 5200, 40, 420));
      stars = [];
      for (let i = 0; i < count; i++) {
        const x = next() * width;
        const y = next() * height;
        const r = 0.5 + Math.pow(next(), 3) * 1.6;
        const phase = next() * Math.PI * 2;
        const rate = 0.4 + next() * 1.1;
        const hidden = blocks.some((b) => x > b.left && x < b.right && y > b.top && y < b.bottom);
        stars.push({ x, y, r, phase, rate, base: hidden ? 0.18 : 0.35 + next() * 0.5, gold: next() < 0.12 });
      }

      const box = stage();
      if (box && box.right - box.left > 120) {
        const w = box.right - box.left;
        const h = box.bottom - box.top;
        const span = Math.min(w * 0.92, h * 1.5);
        const left = box.left + (w - span) / 2;
        const top = box.top + (h - span * 0.4803) / 2;
        dipper = {
          span,
          cx: box.left + w / 2,
          cy: box.top + h / 2,
          points: DIPPER.map(([x, y, mag]) => ({ x: left + x * span, y: top + y * span, size: 2.2 + (3.4 - mag) * 2.4 })),
        };
      } else {
        dipper = null;
      }
    }

    function tint() {
      const style = getComputedStyle(canvas);
      const read = (name, fallback) => style.getPropertyValue(name).trim() || fallback;
      colors = {
        star: read('--star', '#e9e2cf'),
        gold: read('--gilt', '#d6b36a'),
        line: read('--asterism', 'rgba(214,179,106,0.45)'),
        ring: read('--ring', 'rgba(214,179,106,0.16)'),
        violet: read('--violet', '#a99be0'),
      };
    }

    function sparkle(x, y, size, color, alpha) {
      ctx.globalAlpha = alpha;
      ctx.fillStyle = color;
      ctx.beginPath();
      const waist = size * 0.22;
      ctx.moveTo(x, y - size);
      ctx.quadraticCurveTo(x + waist, y - waist, x + size, y);
      ctx.quadraticCurveTo(x + waist, y + waist, x, y + size);
      ctx.quadraticCurveTo(x - waist, y + waist, x - size, y);
      ctx.quadraticCurveTo(x - waist, y - waist, x, y - size);
      ctx.fill();
    }

    function glow(x, y, radius, color, alpha) {
      const g = ctx.createRadialGradient(x, y, 0, x, y, radius);
      g.addColorStop(0, color);
      g.addColorStop(1, 'transparent');
      ctx.globalAlpha = alpha;
      ctx.fillStyle = g;
      ctx.fillRect(x - radius, y - radius, radius * 2, radius * 2);
    }

    // Each star of the Dipper lights in turn from the handle, the whole asterism holds, then it dims and starts again.
    function litOf(index, t) {
      if (still()) return 1;
      const cycle = DIPPER.length * LIGHT_STEP + LIGHT_HOLD;
      const local = t % cycle;
      const on = ease((local - index * LIGHT_STEP) / 0.5);
      const off = local > cycle - 1.2 ? (cycle - local) / 1.2 : 1;
      return t < cycle ? on : 0.35 + 0.65 * Math.min(on, off);
    }

    function pointerBoost(x, y) {
      if (!pointer) return 0;
      const box = canvas.getBoundingClientRect();
      const dx = pointer.x - box.left - x;
      const dy = pointer.y - box.top - y;
      return Math.max(0, 1 - Math.hypot(dx, dy) / 140);
    }

    function draw(now) {
      const t = (now - started) / 1000;
      const surge = Math.max(0, 1 - (now - surgeAt) / 1400);
      ctx.globalAlpha = 1;
      ctx.clearRect(0, 0, width, height);

      for (const s of stars) {
        const twinkle = still() ? 1 : 0.75 + 0.25 * Math.sin(s.phase + t * s.rate);
        const alpha = clamp(s.base * twinkle + pointerBoost(s.x, s.y) * 0.5 + surge * 0.4, 0, 1);
        ctx.globalAlpha = alpha;
        ctx.fillStyle = s.gold ? colors.gold : colors.star;
        ctx.beginPath();
        ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
        ctx.fill();
      }

      if (!dipper) return;
      const { points, span, cx, cy } = dipper;

      // A faint 紫微垣 ring with the 28 mansions marked, turning about once every ten minutes.
      const radius = span * 0.62;
      const turn = still() ? 0 : t * ((Math.PI * 2) / 600);
      ctx.globalAlpha = 1;
      ctx.strokeStyle = colors.ring;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(cx, cy, radius * 0.86, 0, Math.PI * 2);
      ctx.setLineDash([2, 6]);
      ctx.stroke();
      ctx.setLineDash([]);
      for (let i = 0; i < MANSIONS; i++) {
        const a = turn + (i / MANSIONS) * Math.PI * 2;
        const long = i % 7 === 0;
        const inner = radius * (long ? 0.93 : 0.965);
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
        ctx.lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
        ctx.stroke();
      }

      const lit = points.map((_, index) => litOf(index, t));
      ctx.strokeStyle = colors.line;
      ctx.lineWidth = 1.2;
      for (const [a, b] of DIPPER_LINKS) {
        const level = Math.min(lit[a], lit[b]);
        ctx.globalAlpha = 0.25 + 0.75 * level;
        ctx.beginPath();
        ctx.moveTo(points[a].x, points[a].y);
        ctx.lineTo(points[b].x, points[b].y);
        ctx.stroke();
      }
      points.forEach((p, index) => {
        const level = clamp(lit[index] + surge + pointerBoost(p.x, p.y) * 0.4, 0, 1);
        glow(p.x, p.y, p.size * 5, colors.gold, 0.12 + 0.38 * level);
        sparkle(p.x, p.y, p.size * (1 + 0.25 * level), level > 0.5 ? colors.gold : colors.violet, 0.45 + 0.55 * level);
        ctx.globalAlpha = 0.6 + 0.4 * level;
        ctx.fillStyle = colors.star;
        ctx.beginPath();
        ctx.arc(p.x, p.y, Math.max(1, p.size * 0.28), 0, Math.PI * 2);
        ctx.fill();
      });
      ctx.globalAlpha = 1;
    }

    function tick(now) {
      frame = 0;
      draw(now);
      if (!still() && onScreen && !document.hidden) frame = requestAnimationFrame(tick);
    }

    function sync() {
      if (frame) {
        cancelAnimationFrame(frame);
        frame = 0;
      }
      if (onScreen && !document.hidden) frame = requestAnimationFrame(tick);
    }

    function refresh() {
      measure();
      tint();
      chart();
      sync();
    }

    function surge() {
      surgeAt = performance.now();
      sync();
    }

    started = performance.now();
    refresh();
    if ('ResizeObserver' in window) new ResizeObserver(refresh).observe(canvas);
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(([entry]) => {
        onScreen = entry.isIntersecting;
        sync();
      }).observe(canvas);
    }
    document.addEventListener('visibilitychange', sync);
    addEventListener(
      'pointermove',
      (event) => {
        if (event.pointerType === 'mouse') pointer = { x: event.clientX, y: event.clientY };
      },
      { passive: true },
    );

    return { refresh, surge };
  }

  return { mount };
})();
