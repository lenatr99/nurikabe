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
      console.log(msg);
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
  
  // Calculate optimal cell size based on available space and grid dimensions
  const maxWidth = 380; // Max width for the board within the card
  const maxDimension = Math.max(w, h);
  let cellSize = Math.min(32, Math.floor(maxWidth / maxDimension) - 2); // -2 for gaps
  
  // Ensure minimum readable size
  cellSize = Math.max(cellSize, 12);
  
  // Set specific thresholds for common sizes
  if (maxDimension <= 5) {
    cellSize = 32;
  } else if (maxDimension <= 8) {
    cellSize = 28;
  } else if (maxDimension <= 10) {
    cellSize = 24;
  } else if (maxDimension <= 12) {
    cellSize = 20;
  } else if (maxDimension <= 15) {
    cellSize = 18;
  } else {
    cellSize = 16;
  }
  
  board.style.setProperty('--cell', `${cellSize}px`);
  board.style.gridTemplateColumns = `repeat(${w}, ${cellSize}px)`;
  board.style.maxWidth = '100%';
  board.style.width = 'fit-content';
  
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
  const isSolved = ok === 'true';
  const card = document.createElement('div');
  card.className = 'card';
  
  const statusBadge = `<span class="status-badge ${isSolved ? 'solved' : 'unsolved'}">${isSolved ? '✅ Solved' : '⚠️ Unsolved'}</span>`;
  const stepsInfo = steps ? ` • ${steps} steps` : '';
  
  card.innerHTML = `
    <h3>
      Puzzle #${i} ${statusBadge}${stepsInfo}
    </h3>
    <div class="grids">
      <div class="grid-section">
        <div class="label">🧩 Puzzle</div>
      </div>
      <div class="grid-section">
        <div class="label">💡 Solution</div>
      </div>
    </div>
    <div class="legend">Black squares are walls • Numbers show island sizes • Empty cells complete the islands</div>`;
  
  const grids = card.querySelector('.grids');
  renderPuzzleGrid(grids.children[0], puzzle);
  renderSolutionGrid(grids.children[1], flat, puzzle);
  document.getElementById('gallery').appendChild(card);
  return { puzzle, solved: isSolved, steps: Number(steps), solutionFlat: flat };
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

  const items = [];
  const seenPuzzles = new Set(); // Track puzzle strings
  const seenSolutions = new Set(); // Track solution strings for extra safety
  let attempts = 0;
  let duplicateCount = 0;
  const maxAttempts = count * 20; // Increased limit to account for more duplicate checking
  
  while (items.length < count && attempts < maxAttempts) {
    attempts++;
    const p = await generateOnce(opts.w, opts.h, opts.diff, opts.sym);
    
    // Check for puzzle duplicates
    if (seenPuzzles.has(p)) {
      duplicateCount++;
      log(`🔄 Duplicate puzzle detected (attempt ${attempts}, duplicates: ${duplicateCount}), retrying…`);
      continue;
    }
    
    // Check if puzzle is solvable
    const solvedStr = await solvePuzzle(p, opts.diff);
    const [ok, steps, flat] = solvedStr.split(':');
    const isSolved = ok === 'true';
    
    if (!isSolved) {
      // Discard unsolvable puzzles
      log(`❌ Discarded unsolvable puzzle (attempt ${attempts}), generating replacement…`);
      continue;
    }
    
    // Check for solution duplicates (even if puzzle is different, solution might be same)
    if (seenSolutions.has(flat)) {
      duplicateCount++;
      log(`🔄 Duplicate solution detected (attempt ${attempts}, duplicates: ${duplicateCount}), retrying…`);
      continue;
    }
    
    // This puzzle is solvable and unique!
    seenPuzzles.add(p);
    seenSolutions.add(flat);
    const item = addCard(items.length + 1, p, solvedStr);
    items.push(item);
    log(`✅ Got unique solvable puzzle #${items.length}/${count} (attempt ${attempts})`);
    log(`📝 Puzzle: ${p.substring(0, 50)}${p.length > 50 ? '...' : ''}`);
    log(`🎯 Solution: ${flat.substring(0, 50)}${flat.length > 50 ? '...' : ''}`);
    log(`📊 Progress: ${((items.length / count) * 100).toFixed(1)}% complete\n`);
  }
  
  if (items.length < count) {
    log(`⚠️ Warning: Only found ${items.length} solvable puzzles out of ${count} requested after ${attempts} attempts`);
  }

  const key = `nurikabe_${opts.w}x${opts.h}_${opts.diff}_${items.length}puzzles`;
  const meta = { 
    ...opts, 
    count: items.length, 
    timestamp: new Date().toISOString(),
    attempts: attempts,
    duplicatesFound: duplicateCount,
    successRate: `${((items.length / attempts) * 100).toFixed(1)}%`,
    uniquenessRate: `${(((attempts - duplicateCount) / attempts) * 100).toFixed(1)}%`
  };
  const payload = { meta, items };
  localStorage.setItem(key, JSON.stringify(items));
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = Object.assign(document.createElement('a'), { href: url, download: `${key}.json` });
  document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  log(`\n🎉 ===== GENERATION COMPLETE =====`);
  log(`✅ Successfully generated ${items.length} solvable puzzles out of ${count} requested!`);
  log(`📊 Statistics:`);
  log(`   • Total attempts: ${attempts}`);
  log(`   • Duplicates found: ${duplicateCount}`);
  log(`   • Success rate: ${meta.successRate}`);
  log(`   • Uniqueness rate: ${meta.uniquenessRate}`);
  log(`🔍 Quality assurance: NO duplicates (checked both puzzles AND solutions)`);
  log(`💾 Saved ${items.length} unique solved puzzles to "${key}" and downloaded ${key}.json`);
  log(`🔗 All puzzles are guaranteed solvable and 100% unique!`);
}

// ---- UI ----
let isGenerating = false;

function updateProgress(current, total, message = '') {
  const progressContainer = document.getElementById('progressContainer');
  const progressFill = document.getElementById('progressFill');
  const progressText = document.getElementById('progressText');
  
  if (total === 0) {
    progressContainer.style.display = 'none';
    return;
  }
  
  progressContainer.style.display = 'block';
  const percentage = (current / total) * 100;
  progressFill.style.width = `${percentage}%`;
  progressText.textContent = message || `${current} of ${total} puzzles generated`;
}

function showStats(items, opts) {
  const statsContainer = document.getElementById('stats');
  const solvedCount = items.filter(item => item.solved).length;
  const avgSteps = items.reduce((sum, item) => sum + item.steps, 0) / items.length;
  
  statsContainer.innerHTML = `
    <div class="stat-card">
      <div class="stat-value">${items.length}</div>
      <div class="stat-label">Total Puzzles</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">${solvedCount}</div>
      <div class="stat-label">Solved</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">${opts.w}×${opts.h}</div>
      <div class="stat-label">Grid Size</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">${Math.round(avgSteps)}</div>
      <div class="stat-label">Avg Steps</div>
    </div>
  `;
  statsContainer.style.display = 'grid';
}

function toggleLog() {
  const logEl = document.getElementById('log');
  logEl.style.display = logEl.style.display === 'none' ? 'block' : 'none';
}

// Add input validation and live updates
document.addEventListener('DOMContentLoaded', () => {
  const countInput = document.getElementById('puzzleCount');
  const widthInput = document.getElementById('puzzleWidth');
  const heightInput = document.getElementById('puzzleHeight');
  const difficultySelect = document.getElementById('difficulty');
  const generateBtn = document.getElementById('generate');
  
  function updateButtonText() {
    const count = parseInt(countInput.value) || 10;
    const width = parseInt(widthInput.value) || 10;
    const height = parseInt(heightInput.value) || 10;
    const difficulty = difficultySelect.value || 'easy';
    
    if (!isGenerating) {
      generateBtn.textContent = `✨ Generate ${count} × ${width}×${height} ${difficulty} Puzzles`;
    }
  }
  
  [countInput, widthInput, heightInput, difficultySelect].forEach(input => {
    input.addEventListener('input', updateButtonText);
    input.addEventListener('change', updateButtonText);
  });
  
  updateButtonText(); // Initial update
});

document.getElementById('generate').addEventListener('click', async () => {
  if (isGenerating) return;
  
  try {
    isGenerating = true;
    const generateBtn = document.getElementById('generate');
    const logEl = document.getElementById('log');
    
    // Get form values
    const count = parseInt(document.getElementById('puzzleCount').value) || 10;
    const width = parseInt(document.getElementById('puzzleWidth').value) || 10;
    const height = parseInt(document.getElementById('puzzleHeight').value) || 10;
    const difficulty = document.getElementById('difficulty').value || 'easy';
    
    // Validate inputs
    if (count < 1 || count > 100) {
      alert('Number of puzzles must be between 1 and 100');
      return;
    }
    if (width < 3 || width > 20 || height < 3 || height > 20) {
      alert('Puzzle size must be between 3×3 and 20×20');
      return;
    }
    
    // Update UI
    generateBtn.disabled = true;
    generateBtn.textContent = '🔄 Generating...';
    logEl.style.display = 'block';
    logEl.textContent = '';
    
    // Clear previous results
    document.getElementById('gallery').innerHTML = '';
    document.getElementById('stats').style.display = 'none';
    
    log(`🚀 Starting generation of ${count} puzzles (${width}×${height}, ${difficulty})`);
    updateProgress(0, count, 'Initializing...');
    
    const opts = { w: width, h: height, diff: difficulty, sym: 'none' };
    
    // Generate puzzles with progress updates
    const puzzles = [];
    const seen = new Set();
    let attempts = 0;
    const maxAttempts = count * 3; // Allow some retries for duplicates
    
    while (puzzles.length < count && attempts < maxAttempts) {
      attempts++;
      try {
        updateProgress(puzzles.length, count, `Generating puzzle ${puzzles.length + 1}...`);
        const puzzle = await generateOnce(width, height, difficulty, 'none');
        
        if (!seen.has(puzzle)) {
          puzzles.push(puzzle);
          seen.add(puzzle);
          log(`✅ Generated puzzle #${puzzles.length}: ${puzzle.substring(0, 50)}...`);
        } else {
          log(`🔄 Duplicate found, retrying...`);
        }
      } catch (error) {
        log(`❌ Error generating puzzle: ${error.message}`);
        await new Promise(resolve => setTimeout(resolve, 100)); // Small delay before retry
      }
    }
    
    if (puzzles.length === 0) {
      throw new Error('Could not generate any puzzles. Please try different settings.');
    }
    
    log(`🧩 Generated ${puzzles.length} unique puzzles, now solving...`);
    
    // Solve puzzles and display them
    const items = [];
    for (let i = 0; i < puzzles.length; i++) {
      try {
        updateProgress(i, puzzles.length, `Solving puzzle ${i + 1}...`);
        const solvedStr = await solvePuzzle(puzzles[i], difficulty);
        const item = addCard(i + 1, puzzles[i], solvedStr);
        items.push(item);
        log(`🔍 Solved puzzle #${i + 1}`);
      } catch (error) {
        log(`❌ Error solving puzzle #${i + 1}: ${error.message}`);
        // Add unsolved puzzle anyway
        const item = addCard(i + 1, puzzles[i], 'false:0:');
        items.push(item);
      }
    }
    
    updateProgress(0, 0); // Hide progress bar
    
    // Show statistics
    showStats(items, opts);
    
    // Save and download
    const key = `nurikabe_${width}x${height}_${difficulty}_${items.length}puzzles`;
    const payload = { meta: { ...opts, count: items.length, timestamp: new Date().toISOString() }, items };
    localStorage.setItem(key, JSON.stringify(payload));
    
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = Object.assign(document.createElement('a'), { href: url, download: `${key}.json` });
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
    
    log(`💾 Saved ${items.length} puzzles to "${key}" and downloaded JSON file`);
    log(`🎉 Generation complete! Click here to toggle this log.`);
    
    // Make log clickable to hide
    logEl.style.cursor = 'pointer';
    logEl.title = 'Click to hide log';
    logEl.addEventListener('click', toggleLog, { once: true });
    
  } catch (error) {
    log(`💥 Generation failed: ${error.message}`);
    updateProgress(0, 0);
  } finally {
    isGenerating = false;
    const generateBtn = document.getElementById('generate');
    generateBtn.disabled = false;
    generateBtn.textContent = '✨ Generate Puzzles';
  }
});
