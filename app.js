// ---- logging ----
const logEl = document.getElementById('log');
const log = (...args) => {
  const msg = args.map(a => (a && a.stack) ? a.stack : (a && a.message) ? a.message : typeof a === 'string' ? a : JSON.stringify(a)).join(' ');
  logEl.textContent += msg + '\n';
  console.log(...args);
};

// ---- worker ----
// If your worker is in a subfolder, change './solverGenerator.js' accordingly (e.g. './js/solverGenerator.js')
const workerPath = './solverGenerator.js';
let nkWorker;
try {
  nkWorker = new Worker(workerPath);
  nkWorker.addEventListener('error', (e) => log('Worker error:', e.message || e));
  nkWorker.addEventListener('messageerror', (e) => log('Worker messageerror:', e));
} catch (e) {
  log('Failed to construct worker:', e);
  log('Tried URL:', new URL(workerPath, location.href).toString());
}

// ---- worker helpers ----
function generateOnce(w = 5, h = 5, diff = 'easy', sym = 'none') {
  return new Promise((resolve, reject) => {
    if (!nkWorker) return reject(new Error('Worker not available (check 404 on solverGenerator.js)'));
    const onMessage = (e) => {
      const msg = e.data;
      if (typeof msg === 'string' && msg.startsWith('done_')) {
        nkWorker.removeEventListener('message', onMessage);
        resolve(msg.slice(5)); // puzzle string "WxH:cells,"
      }
    };
    const onError = (err) => { nkWorker.removeEventListener('message', onMessage); reject(err); };
    nkWorker.addEventListener('message', onMessage);
    nkWorker.addEventListener('error', onError, { once: true });
    nkWorker.postMessage(`generate_${w}_${h}_${diff}_${sym}`);
  });
}

function solvePuzzle(puzzleString, diff = 'easy') {
  return new Promise((resolve, reject) => {
    if (!nkWorker) return reject(new Error('Worker not available (check 404 on solverGenerator.js)'));
    const onMessage = (e) => {
      const msg = e.data;
      if (typeof msg === 'string' && msg.startsWith('done_')) {
        nkWorker.removeEventListener('message', onMessage);
        resolve(msg.slice(5)); // "true|false:steps:flat"
      }
    };
    const onError = (err) => { nkWorker.removeEventListener('message', onMessage); reject(err); };
    nkWorker.addEventListener('message', onMessage);
    nkWorker.addEventListener('error', onError, { once: true });
    nkWorker.postMessage(`solve_${puzzleString}_${diff}`);
  });
}

// ---- parsing & rendering ----
function parsePuzzleString(s) {
  const [wh, list] = s.split(':');
  const [w, h] = wh.split('x').map(Number);
  const cells = list.split(',').filter(Boolean);
  return { w, h, cells };
}
function flatToGrid(flat, w, h) {
  const cells = flat.split(',').filter(Boolean);
  const grid = [];
  for (let r = 0; r < h; r++) grid.push(cells.slice(r * w, (r + 1) * w));
  return grid;
}
function makeBoardEl(w, h) {
  const board = document.createElement('div');
  board.className = 'board';
  board.style.gridTemplateColumns = `repeat(${w}, var(--cell))`;
  return board;
}
function renderPuzzleGrid(container, puzzleString) {
  const { w, h, cells } = parsePuzzleString(puzzleString);
  const board = makeBoardEl(w, h);
  cells.forEach(v => {
    const c = document.createElement('div');
    c.className = 'cell';
    if (v === '-') { c.textContent = ''; c.classList.add('unknown'); }
    else { c.textContent = v; }
    board.appendChild(c);
  });
  container.appendChild(board);
}
function renderSolutionGrid(container, solutionFlat, puzzleString) {
  const { w, h } = parsePuzzleString(puzzleString);
  const grid = flatToGrid(solutionFlat, w, h);
  const board = makeBoardEl(w, h);
  grid.flat().forEach(v => {
    const c = document.createElement('div');
    if (v === '#') { c.className = 'cell wall'; c.textContent = ''; }
    else if (v === '*') { c.className = 'cell'; c.textContent = ''; }
    else { c.className = 'cell'; c.textContent = v; }
    board.appendChild(c);
  });
  container.appendChild(board);
}
function addCard(i, puzzle, solvedStr) {
  const [ok, steps, flat] = solvedStr.split(':');
  const card = document.createElement('div');
  card.className = 'card';
  card.innerHTML = `<h3>Puzzle #${i} — ${ok === 'true' ? 'solved' : 'unsolved'} (steps: ${steps})</h3>
    <div class="grids">
      <div><div class="label">Puzzle</div></div>
      <div><div class="label">Solution</div></div>
    </div>
    <div class="legend">Walls = black squares; island cells are blank; clue numbers stay visible.</div>`;
  const grids = card.querySelector('.grids');
  renderPuzzleGrid(grids.children[0], puzzle);
  renderSolutionGrid(grids.children[1], flat, puzzle);
  document.getElementById('gallery').appendChild(card);
  return { puzzle, solved: ok === 'true', steps: Number(steps), solutionFlat: flat };
}

// ---- batch ----
async function generateMany(count = 10, opts = { w: 5, h: 5, diff: 'easy', sym: 'none', dedupe: true }) {
  const { w, h, diff, sym, dedupe } = opts;
  const out = [];
  const seen = new Set();
  while (out.length < count) {
    const p = await generateOnce(w, h, diff, sym);
    if (!dedupe || !seen.has(p)) { out.push(p); seen.add(p); log(`Got #${out.length}: ${p}`); }
    else log('Duplicate, retrying…');
  }
  return out;
}
async function generateSolveAndShow(count = 10, opts = { w: 5, h: 5, diff: 'easy', sym: 'none' }) {
  const gallery = document.getElementById('gallery');
  if (!gallery) throw new Error('Missing #gallery element in HTML');
  gallery.innerHTML = '';

  const puzzles = await generateMany(count, { ...opts, dedupe: true });
  const items = [];
  for (let i = 0; i < puzzles.length; i++) {
    const p = puzzles[i];
    const solvedStr = await solvePuzzle(p, opts.diff);
    const item = addCard(i + 1, p, solvedStr);
    items.push(item);
  }

  const key = `nurikabe_${opts.w}x${opts.h}_${opts.diff}_with_solutions`;
  const payload = { meta: opts, items };
  localStorage.setItem(key, JSON.stringify(items));
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = Object.assign(document.createElement('a'), { href: url, download: `${key}.json` });
  document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  log(`Saved ${items.length} puzzles + solutions to "${key}" and downloaded ${key}.json`);
}

// ---- UI ----
document.getElementById('gen').addEventListener('click', async () => {
  try {
    log('Generating 10 puzzles (5×5, easy) and showing solutions…');
    await generateSolveAndShow(10, { w: 5, h: 5, diff: 'easy', sym: 'none' });
    log('Done.');
  } catch (e) {
    log('Batch failed:', e);
  }
});
