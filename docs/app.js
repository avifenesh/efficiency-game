// Language Efficiency Race - Visualization App

// Language color mapping
const LANGUAGE_COLORS = {
  python: "#3776ab",
  nodejs: "#68a063",
  c: "#555555",
  cpp: "#00599c",
  csharp: "#239120",
  rust: "#ce422b",
  go: "#00add8",
  zig: "#f7a41d",
  nim: "#ffe953",
  mojo: "#ff6b35",
  java: "#007396",
  kotlin: "#7f52ff",
  ruby: "#cc342d",
  php: "#777bb4",
  scala: "#dc322f",
  elixir: "#4e2a8e",
  julia: "#9558b2",
  perl: "#39457e",
};

const DATASET_PATHS = {
  small: "../data/results-small.json",
  medium: "../data/results-medium.json",
  large: "../data/results-large.json",
};

let currentDataset = null;
let datasetButtons = [];
let sprintCleanup = null;
let compareChart = null;
let currentChartMode = "time";
let chartTabs = [];
let currentLanguages = {};
const heroCounterState = new Map();

const reducedMotionQuery = window.matchMedia(
  "(prefers-reduced-motion: reduce)"
);
let prefersReducedMotion = reducedMotionQuery.matches;
if (typeof reducedMotionQuery.addEventListener === "function") {
  reducedMotionQuery.addEventListener("change", (event) => {
    prefersReducedMotion = event.matches;
  });
} else if (typeof reducedMotionQuery.addListener === "function") {
  reducedMotionQuery.addListener((event) => {
    prefersReducedMotion = event.matches;
  });
}

const heroElements = {
  fastestTime: document.getElementById("hero-fastest-time"),
  fastestLanguage: document.getElementById("hero-fastest-language"),
  fastestGap: document.getElementById("hero-fastest-gap"),
  stingiestMemory: document.getElementById("hero-stingiest-memory"),
  stingiestLanguage: document.getElementById("hero-stingiest-language"),
  stingiestGap: document.getElementById("hero-stingiest-gap"),
  languageCount: document.getElementById("hero-language-count"),
  datasetSize: document.getElementById("hero-dataset-size"),
  lines: document.getElementById("hero-lines"),
};

function hexToRgba(hex, alpha = 1) {
    if (!hex) return `rgba(255,255,255,${alpha})`;
    let parsed = hex.replace('#', '');
    if (parsed.length === 3) {
        parsed = parsed.split('').map(ch => ch + ch).join('');
    }
    const intVal = parseInt(parsed, 16);
    if (Number.isNaN(intVal)) return `rgba(255,255,255,${alpha})`;
    const r = (intVal >> 16) & 255;
    const g = (intVal >> 8) & 255;
    const b = intVal & 255;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function formatLineCountShort(value = 0) {
  if (!Number.isFinite(value) || value <= 0) return "0";
  if (value >= 1_000_000) {
    const millions = value / 1_000_000;
    return `${
      Number.isInteger(millions) ? millions.toFixed(0) : millions.toFixed(1)
    }M`;
  }
  if (value >= 1_000) {
    const thousands = value / 1_000;
    return `${
      Number.isInteger(thousands) ? thousands.toFixed(0) : thousands.toFixed(1)
    }K`;
  }
  return value.toLocaleString();
}

function animateNumber(
  element,
  targetValue,
  { duration = 900, decimals = 2, suffix = "", prefix = "" } = {}
) {
  if (!element || typeof targetValue !== "number" || Number.isNaN(targetValue))
    return;
  if (prefersReducedMotion) {
    element.textContent = `${prefix}${targetValue.toFixed(decimals)}${suffix}`;
    heroCounterState.set(element, targetValue);
    return;
  }

  const startingValue = heroCounterState.has(element)
    ? heroCounterState.get(element)
    : 0;
  const delta = targetValue - startingValue;
  const startTime = performance.now();

  function step(now) {
    const elapsed = Math.min(1, (now - startTime) / duration);
    const eased = 1 - Math.pow(1 - elapsed, 3);
    const currentValue = startingValue + delta * eased;
    element.textContent = `${prefix}${currentValue.toFixed(decimals)}${suffix}`;
    if (elapsed < 1) {
      requestAnimationFrame(step);
    } else {
      heroCounterState.set(element, targetValue);
    }
  }

  requestAnimationFrame(step);
}

// Load and process data
async function loadData(size = "medium") {
  const normalized = (size || "medium").toLowerCase();

  // First, try to use embedded datasets (works with file:// protocol)
  if (window.BENCHMARK_DATASETS && window.BENCHMARK_DATASETS[normalized]) {
    console.log(`Loading ${normalized} dataset from embedded data`);
    return window.BENCHMARK_DATASETS[normalized];
  }

  // Fallback to single embedded data
  if (window.BENCHMARK_DATA) {
    const embeddedSize =
      window.BENCHMARK_DATA?.metadata?.log_size?.toLowerCase();
    if (!size || embeddedSize === normalized) {
      return window.BENCHMARK_DATA;
    }
  }

  // Last resort: try to fetch (will fail with file:// but works with http://)
  const path = DATASET_PATHS[normalized] || DATASET_PATHS.medium;
  try {
    console.log(`Fetching ${normalized} dataset from ${path}`);
    const response = await fetch(path, { cache: "no-store" });
    if (!response.ok) throw new Error(`Failed to load dataset: ${normalized}`);
    return await response.json();
  } catch (error) {
    console.warn("Error loading dataset:", error.message);
    // Fallback to any embedded data
    if (window.BENCHMARK_DATA) return window.BENCHMARK_DATA;
    if (window.BENCHMARK_DATASETS) {
      const firstAvailable = Object.keys(window.BENCHMARK_DATASETS)[0];
      if (firstAvailable) return window.BENCHMARK_DATASETS[firstAvailable];
    }
    return null;
  }
}

// Format language name for display
function formatLanguageName(lang) {
  const names = {
    nodejs: "Node.js",
    cpp: "C++",
    csharp: "C#",
  };
  return names[lang] || lang.charAt(0).toUpperCase() + lang.slice(1);
}

// Update metadata section
function updateMetadata(metadata, languages = {}) {
  const metadataDiv = document.getElementById("metadata");
  const heroSummary = document.getElementById("hero-summary");
  const entries = Object.entries(languages);
  const date = new Date(metadata.timestamp);
  if (metadataDiv) {
    metadataDiv.textContent = `📅 ${date.toLocaleDateString()} · ${
      metadata.log_size.charAt(0).toUpperCase() + metadata.log_size.slice(1)
    } dataset · ${metadata.iterations} iterations`;
  }
  if (heroSummary && entries.length) {
    const fastest = [...entries].sort(
      (a, b) => a[1].stats.time_avg - b[1].stats.time_avg
    )[0];
    const efficient = [...entries].sort(
      (a, b) => a[1].stats.memory_avg - b[1].stats.memory_avg
    )[0];
    heroSummary.textContent = `� ${formatLanguageName(
      fastest[0]
    )} ${fastest[1].stats.time_avg.toFixed(3)}s · 💾 ${formatLanguageName(
      efficient[0]
    )} ${efficient[1].stats.memory_avg.toFixed(2)} MB · ${
      entries.length
    } languages`;
  }

  updateHeroInsights(entries, metadata);
  updateFooter(metadata);
}

// Update footer with dynamic dataset info
function updateFooter(metadata) {
  const footer = document.querySelector(".footer");
  if (!footer) return;

  const lineCount = metadata.line_count || 0;
  const lineCountText = formatLineCountShort(lineCount);

  const sizeText =
    metadata.log_size.charAt(0).toUpperCase() + metadata.log_size.slice(1);

  footer.innerHTML = `
        <p>Benchmark Methodology: ${metadata.iterations} iterations per language, measuring execution time and peak memory usage on macOS</p>
        <p>Task: Concurrent processing of ${lineCountText} log lines (${sizeText} dataset) to detect ERROR and WARN patterns</p>
    `;
}

function updateHeroInsights(entries, metadata = {}) {
  if (!entries.length) {
    if (heroElements.fastestTime)
      heroElements.fastestTime.textContent = "0.000s";
    if (heroElements.fastestLanguage)
      heroElements.fastestLanguage.textContent = "—";
    if (heroElements.fastestGap)
      heroElements.fastestGap.textContent = "Gap 0.000s";
    if (heroElements.stingiestMemory)
      heroElements.stingiestMemory.textContent = "0.00 MB";
    if (heroElements.stingiestLanguage)
      heroElements.stingiestLanguage.textContent = "—";
    if (heroElements.stingiestGap)
      heroElements.stingiestGap.textContent = "Gap 0.00 MB";
    if (heroElements.languageCount)
      heroElements.languageCount.textContent = "0";
    if (heroElements.datasetSize) heroElements.datasetSize.textContent = "—";
    if (heroElements.lines) heroElements.lines.textContent = "0 log lines";
    return;
  }

  const sortedByTime = [...entries].sort(
    (a, b) => a[1].stats.time_avg - b[1].stats.time_avg
  );
  const sortedByMemory = [...entries].sort(
    (a, b) => a[1].stats.memory_avg - b[1].stats.memory_avg
  );

  const fastest = sortedByTime[0];
  const timeRunnerUp = sortedByTime[1];
  const memoryLeader = sortedByMemory[0];
  const memoryRunnerUp = sortedByMemory[1];

  if (heroElements.fastestTime) {
    animateNumber(heroElements.fastestTime, fastest[1].stats.time_avg, {
      decimals: 3,
      suffix: "s",
    });
  }
  if (heroElements.fastestLanguage) {
    heroElements.fastestLanguage.textContent = formatLanguageName(fastest[0]);
  }
  if (heroElements.fastestGap) {
    const gap = timeRunnerUp
      ? Math.max(0, timeRunnerUp[1].stats.time_avg - fastest[1].stats.time_avg)
      : 0;
    heroElements.fastestGap.textContent = `Gap ${gap.toFixed(3)}s`;
  }

  if (heroElements.stingiestMemory) {
    animateNumber(
      heroElements.stingiestMemory,
      memoryLeader[1].stats.memory_avg,
      { decimals: 2, suffix: " MB" }
    );
  }
  if (heroElements.stingiestLanguage) {
    heroElements.stingiestLanguage.textContent = formatLanguageName(
      memoryLeader[0]
    );
  }
  if (heroElements.stingiestGap) {
    const memoryGap = memoryRunnerUp
      ? Math.max(
          0,
          memoryRunnerUp[1].stats.memory_avg - memoryLeader[1].stats.memory_avg
        )
      : 0;
    heroElements.stingiestGap.textContent = `Gap ${memoryGap.toFixed(2)} MB`;
  }

  if (heroElements.languageCount) {
    animateNumber(heroElements.languageCount, entries.length, { decimals: 0 });
  }

  if (heroElements.datasetSize) {
    const datasetLabel = metadata.log_size
      ? metadata.log_size.charAt(0).toUpperCase() + metadata.log_size.slice(1)
      : "—";
    const iterations = Number.isFinite(metadata.iterations)
      ? metadata.iterations
      : 0;
    heroElements.datasetSize.textContent = `${datasetLabel} dataset · ${iterations} iterations`;
  }

  if (heroElements.lines) {
    const lines = Number.isFinite(metadata.line_count)
      ? metadata.line_count
      : 0;
    heroElements.lines.textContent = `${formatLineCountShort(lines)} log lines`;
  }
}

// Create time comparison chart
function getChartConfig(mode, languages) {
  const entries = Object.entries(languages);
  const sortedLangs = entries.sort((a, b) =>
    mode === "time"
      ? a[1].stats.time_avg - b[1].stats.time_avg
      : a[1].stats.memory_avg - b[1].stats.memory_avg
  );
  const labels = sortedLangs.map(([name]) => formatLanguageName(name));
  const data = sortedLangs.map(([_, lang]) =>
    mode === "time" ? lang.stats.time_avg : lang.stats.memory_avg
  );
  const colors = sortedLangs.map(([name]) => LANGUAGE_COLORS[name] || "#666");
  const label =
    mode === "time"
      ? "Average Execution Time (seconds)"
      : "Average Memory Usage (MB)";
  const tooltip =
    mode === "time"
      ? (value) => `${value.toFixed(3)}s`
      : (value) => `${value.toFixed(2)} MB`;
  const tick =
    mode === "time"
      ? (value) => value.toFixed(2) + "s"
      : (value) => value.toFixed(0) + " MB";
  return { labels, data, colors, label, tooltip, tick };
}

function renderComparisonChart() {
  const canvas = document.getElementById("compareChart");
  if (!canvas || !Object.keys(currentLanguages).length) return;
  const ctx = canvas.getContext("2d");
  const config = getChartConfig(currentChartMode, currentLanguages);

  if (!compareChart) {
    compareChart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: config.labels,
        datasets: [
          {
            label: config.label,
            data: config.data,
            backgroundColor: config.colors,
            borderColor: config.colors.map((c) => c + "dd"),
            borderWidth: 2,
            borderRadius: 8,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            backgroundColor: "rgba(0, 0, 0, 0.8)",
            padding: 12,
            titleFont: { size: 14 },
            bodyFont: { size: 13 },
            callbacks: {
              label: (context) => config.tooltip(context.parsed.y),
            },
          },
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: "rgba(255, 255, 255, 0.1)",
            },
            ticks: {
              color: "#9aa0a6",
              callback: (value) => config.tick(value),
            },
          },
          x: {
            grid: {
              display: false,
            },
            ticks: {
              color: "#9aa0a6",
            },
          },
        },
      },
    });
  } else {
    const dataset = compareChart.data.datasets[0];
    compareChart.data.labels = config.labels;
    dataset.label = config.label;
    dataset.data = config.data;
    dataset.backgroundColor = config.colors;
    dataset.borderColor = config.colors.map((c) => c + "dd");
    compareChart.options.scales.y.ticks.callback = (value) =>
      config.tick(value);
    compareChart.options.plugins.tooltip.callbacks.label = (context) =>
      config.tooltip(context.parsed.y);
    compareChart.update();
  }
}

// Create sprint track visualization
function createSprintTrack(languages) {
  const canvas = document.getElementById("velocityCanvas");
  const legend = document.getElementById("velocityLegend");
  const toggleBtn = document.getElementById("loop-toggle");
  const speedSlider = document.getElementById("loop-speed");
  const speedLabel = document.getElementById("loop-speed-label");

  if (!canvas || !legend) return;

  const entries = Object.entries(languages);
  if (!entries.length) return;

  const times = entries.map(([_, lang]) => lang.stats.time_avg);
  const memories = entries.map(([_, lang]) => lang.stats.memory_avg);
  const cpus = entries.map(([_, lang]) => lang.stats.cpu_avg ?? 0);
  const fastest = Math.min(...times);
  const minMemory = Math.min(...memories);
  const maxMemory = Math.max(...memories);
  const minCpu = Math.min(...cpus);
  const maxCpu = Math.max(...cpus);
  const memoryRange = maxMemory - minMemory || 1;
  const cpuRange = maxCpu - minCpu || 1;

  let laneSpacing = 58;
  const lanePadding = 70;
  const minTrackHeight = 360;

  const baseLapRate = 0.35; // lap fraction per second for fastest implementation

  const runners = entries.map(([name, lang], index) => {
    const memoryNorm = (lang.stats.memory_avg - minMemory) / memoryRange;
    const cpuNorm = (lang.stats.cpu_avg - minCpu) / cpuRange;
    return {
      name,
      label: formatLanguageName(name),
      color: LANGUAGE_COLORS[name] || "#7b8ba0",
      time: lang.stats.time_avg,
      memory: lang.stats.memory_avg,
      cpu: lang.stats.cpu_avg,
      lapRate: baseLapRate * (fastest / lang.stats.time_avg),
      size: 12 + memoryNorm * 18,
      trail: 0.2 + cpuNorm * 0.8,
      progress: (index / entries.length) % 1,
    };
  });

  const trackHeight = Math.max(
    minTrackHeight,
    lanePadding * 2 + laneSpacing * Math.max(0, runners.length - 1)
  );
  canvas.style.height = `${trackHeight}px`;
  canvas.parentElement.style.height = `${trackHeight}px`;

  legend.innerHTML = "";
  const legendData = [...runners].sort((a, b) => a.time - b.time);
  legendData.forEach((runner) => {
    const item = document.createElement("div");
    item.className = "legend-item";
    item.innerHTML = `
            <span class="legend-swatch" style="background:${
              runner.color
            }"></span>
            <div>
                    <div class="legend-label">${runner.label}</div>
                    <div class="legend-meta">
                        ${runner.time.toFixed(3)}s • ${
      runner.cpu?.toFixed(0) ?? "–"
    }% CPU • ${runner.memory.toFixed(1)} MB
                    </div>
                </div>
        `;
    legend.appendChild(item);
  });

  const ctx = canvas.getContext("2d");
  let pixelRatio = window.devicePixelRatio || 1;

  function resize() {
    pixelRatio = window.devicePixelRatio || 1;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    canvas.width = width * pixelRatio;
    canvas.height = height * pixelRatio;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.scale(pixelRatio, pixelRatio);
  }

  resize();
  window.addEventListener("resize", resize);

  let running = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let speedMultiplier = 1;
  let lastTime = performance.now();
  let destroyed = false;
  let animationId = null;
  const finishCounts = Object.fromEntries(runners.map((r) => [r.name, 0]));

  if (toggleBtn) {
    toggleBtn.textContent = running ? "Pause Loop" : "Play Loop";
    toggleBtn.onclick = () => {
      running = !running;
      toggleBtn.textContent = running ? "Pause Loop" : "Play Loop";
    };
  }

  if (speedSlider && speedLabel) {
    const updateLabel = () => {
      speedLabel.textContent = `${speedMultiplier.toFixed(1)}x`;
    };
    speedSlider.oninput = (event) => {
      speedMultiplier = parseFloat(event.target.value);
      updateLabel();
    };
    updateLabel();
  }

  function render(timestamp) {
    if (destroyed) return;
    const now = timestamp || performance.now();
    const delta = Math.min(0.1, (now - lastTime) / 1000);
    lastTime = now;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    const startX = 110;
    const endX = width - 80;
    const trackLength = Math.max(80, endX - startX);
    const orderedRunners = [...runners].sort(
      (a, b) => finishCounts[b.name] - finishCounts[a.name] || a.time - b.time
    );
    const laneMap = new Map();
    orderedRunners.forEach((runner, idx) => laneMap.set(runner.name, idx));
    const laneOffset = (height - laneSpacing * (orderedRunners.length - 1)) / 2;

    ctx.clearRect(0, 0, width, height);

    // Draw lanes
    ctx.save();
    ctx.strokeStyle = "rgba(255,255,255,0.08)";
    ctx.lineWidth = 1;
    orderedRunners.forEach((runner, laneIndex) => {
      const laneY = laneOffset + laneIndex * laneSpacing;
      ctx.beginPath();
      ctx.moveTo(startX - 40, laneY);
      ctx.lineTo(endX + 40, laneY);
      ctx.stroke();
    });
    ctx.restore();

    // Lane labels
    ctx.save();
    ctx.font =
      '600 14px "Inter", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
    ctx.textBaseline = "middle";
    orderedRunners.forEach((runner, laneIndex) => {
      const laneY = laneOffset + laneIndex * laneSpacing;
      const labelX = Math.max(16, startX - 110);
      ctx.fillStyle = hexToRgba("#0a0e27", 0.65);
      const finishText =
        finishCounts[runner.name] > 0 ? ` · ${finishCounts[runner.name]}` : "";
      const text = runner.label + finishText;
      const textWidth = ctx.measureText(text).width;
      const paddingX = 14;
      const paddingY = 10;
      const pillWidth = textWidth + paddingX * 2;
      const pillHeight = paddingY;
      const pillY = laneY - pillHeight / 2;
      const pillX = labelX - paddingX;
      ctx.beginPath();
      ctx.roundRect(pillX - 4, pillY - 2, pillWidth + 8, pillHeight + 4, 999);
      ctx.fill();
      ctx.fillStyle = runner.color;
      ctx.fillText(text, labelX, laneY);
    });
    ctx.restore();

    // Draw start/finish columns
    ctx.fillStyle = "rgba(255,255,255,0.15)";
    ctx.fillRect(startX - 6, 30, 4, height - 60);
    ctx.fillRect(endX + 2, 30, 4, height - 60);

    orderedRunners.forEach((runner) => {
      if (running) {
        const prevProgress = runner.progress;
        runner.progress += delta * runner.lapRate * speedMultiplier;
        if (runner.progress >= 1) {
          runner.progress -= 1;
          finishCounts[runner.name] += 1;
        }
      }

      const laneIndex = laneMap.get(runner.name) ?? 0;
      const laneY = laneOffset + laneIndex * laneSpacing;
      const x = startX + runner.progress * trackLength;
      const capsuleWidth = Math.max(36, runner.size * 1.8);
      const capsuleHeight = runner.size;

      // Trail represents CPU usage
      ctx.save();
      ctx.strokeStyle = hexToRgba(runner.color, 0.45);
      ctx.lineWidth = Math.max(2, capsuleHeight * 0.45);
      ctx.beginPath();
      ctx.moveTo(startX, laneY);
      ctx.lineTo(x, laneY);
      ctx.stroke();
      ctx.restore();

      // Runner capsule
      ctx.save();
      ctx.shadowColor = hexToRgba(runner.color, 0.85);
      ctx.shadowBlur = 12 + runner.trail * 18;
      ctx.fillStyle = runner.color;
      const halfWidth = capsuleWidth / 2;
      const halfHeight = capsuleHeight / 2;
      ctx.beginPath();
      ctx.moveTo(x - halfWidth + halfHeight, laneY - halfHeight);
      ctx.lineTo(x + halfWidth - halfHeight, laneY - halfHeight);
      ctx.arc(
        x + halfWidth - halfHeight,
        laneY,
        halfHeight,
        -Math.PI / 2,
        Math.PI / 2
      );
      ctx.lineTo(x - halfWidth + halfHeight, laneY + halfHeight);
      ctx.arc(
        x - halfWidth + halfHeight,
        laneY,
        halfHeight,
        Math.PI / 2,
        -Math.PI / 2
      );
      ctx.closePath();
      ctx.fill();
      ctx.restore();

      ctx.strokeStyle = "rgba(255,255,255,0.35)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(x - halfWidth + halfHeight, laneY - halfHeight);
      ctx.lineTo(x + halfWidth - halfHeight, laneY - halfHeight);
      ctx.arc(
        x + halfWidth - halfHeight,
        laneY,
        halfHeight,
        -Math.PI / 2,
        Math.PI / 2
      );
      ctx.lineTo(x - halfWidth + halfHeight, laneY + halfHeight);
      ctx.arc(
        x - halfWidth + halfHeight,
        laneY,
        halfHeight,
        Math.PI / 2,
        -Math.PI / 2
      );
      ctx.stroke();
    });

    animationId = requestAnimationFrame(render);
  }

  animationId = requestAnimationFrame(render);

  return () => {
    destroyed = true;
    if (animationId) cancelAnimationFrame(animationId);
  };
}

// Create leaderboard table
function createLeaderboard(languages) {
  const tbody = document.getElementById("leaderboard-body");
  if (!tbody) return;
  tbody.innerHTML = "";

  const sortedLangs = Object.entries(languages).sort(
    (a, b) => a[1].stats.time_avg - b[1].stats.time_avg
  );
  if (!sortedLangs.length) return;

  const fastestTime = sortedLangs[0][1].stats.time_avg;

  sortedLangs.forEach(([name, lang], index) => {
    const rank = index + 1;
    const multiplier = lang.stats.time_avg / fastestTime;

    let speedClass = "speed-1x";
    let speedText = "1.0x";
    if (multiplier > 1) {
      speedText = multiplier.toFixed(1) + "x";
      speedClass = multiplier > 5 ? "speed-very-slow" : "speed-slow";
    }

    const row = document.createElement("tr");
    row.innerHTML = `
            <td><span class="rank rank-${rank}">${rank}</span></td>
            <td><span class="language-name">${formatLanguageName(
              name
            )}</span></td>
            <td>${lang.stats.time_avg.toFixed(3)}</td>
            <td>${lang.stats.memory_avg.toFixed(2)}</td>
            <td><span class="speed-multiplier ${speedClass}">${speedText}</span></td>
        `;
    tbody.appendChild(row);
  });
}

function renderDashboard(data) {
  currentLanguages = data.languages || {};
  const detectedSize = data.metadata?.log_size?.toLowerCase();
  if (detectedSize && detectedSize !== currentDataset) {
    currentDataset = detectedSize;
    setActiveDatasetButton(currentDataset);
  }
  updateMetadata(data.metadata, currentLanguages);
  if (sprintCleanup) sprintCleanup();
  sprintCleanup = createSprintTrack(currentLanguages) || null;
  renderComparisonChart();
  createLeaderboard(currentLanguages);
}

function setActiveDatasetButton(size) {
  datasetButtons.forEach((btn) =>
    btn.classList.toggle("active", btn.dataset.size === size)
  );
}

function setupDatasetSwitcher(defaultSize) {
  datasetButtons = Array.from(document.querySelectorAll(".dataset-button"));
  if (!datasetButtons.length) return;
  datasetButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = btn.dataset.size;
      if (target && target !== currentDataset) {
        loadDataset(target);
      }
    });
  });
  setActiveDatasetButton(defaultSize);
}

function setupChartTabs() {
  chartTabs = Array.from(document.querySelectorAll(".chart-tab"));
  chartTabs.forEach((btn) =>
    btn.classList.toggle("active", btn.dataset.chart === currentChartMode)
  );
  chartTabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const mode = tab.dataset.chart;
      if (!mode || mode === currentChartMode) return;
      currentChartMode = mode;
      chartTabs.forEach((btn) => btn.classList.toggle("active", btn === tab));
      renderComparisonChart();
    });
  });
}

async function loadDataset(size) {
  currentDataset = (size || "medium").toLowerCase();
  setActiveDatasetButton(currentDataset);
  const data = await loadData(currentDataset);
  if (!data) {
    document.body.innerHTML =
      '<div style="text-align:center;padding:2rem;color:#ff3366;">Error loading dataset. Ensure results files exist.</div>';
    return;
  }
  renderDashboard(data);
}

// Initialize the app
async function init() {
  setupChartTabs();
  const defaultDataset =
    window.BENCHMARK_DATA?.metadata?.log_size?.toLowerCase() || "medium";
  setupDatasetSwitcher(defaultDataset);
  await loadDataset(defaultDataset);
}

// Start when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
