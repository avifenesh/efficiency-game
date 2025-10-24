// Language Efficiency Race - Visualization App

// Language color mapping
const LANGUAGE_COLORS = {
    python: '#3776ab',
    nodejs: '#68a063',
    c: '#555555',
    cpp: '#00599c',
    csharp: '#239120',
    rust: '#ce422b',
    go: '#00add8',
    zig: '#f7a41d',
    nim: '#ffe953',
    mojo: '#ff6b35',
    java: '#007396',
    kotlin: '#7f52ff',
    ruby: '#cc342d',
    php: '#777bb4',
    scala: '#dc322f',
    elixir: '#4e2a8e',
    perl: '#39457e'
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

// Load and process data
async function loadData() {
    // Use embedded data to avoid CORS issues with file:// protocol
    if (window.BENCHMARK_DATA) {
        return window.BENCHMARK_DATA;
    }
    
    // Fallback to fetch if running from a server
    try {
        const response = await fetch('results.json');
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error loading data:', error);
        return null;
    }
}

// Format language name for display
function formatLanguageName(lang) {
    const names = {
        nodejs: 'Node.js',
        cpp: 'C++',
        csharp: 'C#'
    };
    return names[lang] || lang.charAt(0).toUpperCase() + lang.slice(1);
}

// Update metadata section
function updateMetadata(metadata) {
    const metadataDiv = document.getElementById('metadata');
    const date = new Date(metadata.timestamp);
    metadataDiv.innerHTML = `
        📅 ${date.toLocaleDateString()} | 
        📊 ${metadata.log_size.charAt(0).toUpperCase() + metadata.log_size.slice(1)} dataset | 
        🔄 ${metadata.iterations} iterations
    `;
}

// Update summary statistics
function updateSummary(languages) {
    const entries = Object.entries(languages);
    
    // Find fastest by time
    const fastest = entries.reduce((min, curr) => 
        curr[1].stats.time_avg < min[1].stats.time_avg ? curr : min
    );
    
    // Find most memory efficient
    const efficient = entries.reduce((min, curr) => 
        curr[1].stats.memory_avg < min[1].stats.memory_avg ? curr : min
    );
    
    document.getElementById('fastest').textContent = formatLanguageName(fastest[0]);
    document.getElementById('efficient').textContent = formatLanguageName(efficient[0]);
    document.getElementById('total').textContent = entries.length;
}

// Create time comparison chart
function createTimeChart(languages) {
    const ctx = document.getElementById('timeChart').getContext('2d');
    
    const sortedLangs = Object.entries(languages).sort((a, b) => 
        a[1].stats.time_avg - b[1].stats.time_avg
    );
    
    const labels = sortedLangs.map(([name]) => formatLanguageName(name));
    const data = sortedLangs.map(([_, lang]) => lang.stats.time_avg);
    const colors = sortedLangs.map(([name]) => LANGUAGE_COLORS[name] || '#666');
    
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Average Execution Time (seconds)',
                data: data,
                backgroundColor: colors,
                borderColor: colors.map(c => c + 'dd'),
                borderWidth: 2,
                borderRadius: 8
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    padding: 12,
                    titleFont: { size: 14 },
                    bodyFont: { size: 13 },
                    callbacks: {
                        label: (context) => `${context.parsed.y.toFixed(3)}s`
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: '#9aa0a6',
                        callback: (value) => value.toFixed(2) + 's'
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#9aa0a6'
                    }
                }
            }
        }
    });
}

// Create memory comparison chart
function createMemoryChart(languages) {
    const ctx = document.getElementById('memoryChart').getContext('2d');
    
    const sortedLangs = Object.entries(languages).sort((a, b) => 
        a[1].stats.memory_avg - b[1].stats.memory_avg
    );
    
    const labels = sortedLangs.map(([name]) => formatLanguageName(name));
    const data = sortedLangs.map(([_, lang]) => lang.stats.memory_avg);
    const colors = sortedLangs.map(([name]) => LANGUAGE_COLORS[name] || '#666');
    
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Average Memory Usage (MB)',
                data: data,
                backgroundColor: colors,
                borderColor: colors.map(c => c + 'dd'),
                borderWidth: 2,
                borderRadius: 8
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    padding: 12,
                    titleFont: { size: 14 },
                    bodyFont: { size: 13 },
                    callbacks: {
                        label: (context) => `${context.parsed.y.toFixed(2)} MB`
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(255, 255, 255, 0.1)'
                    },
                    ticks: {
                        color: '#9aa0a6',
                        callback: (value) => value.toFixed(0) + ' MB'
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#9aa0a6'
                    }
                }
            }
        }
    });
}

// Create kinetic pace visualization
function createVelocityLoop(languages) {
    const canvas = document.getElementById('velocityCanvas');
    const legend = document.getElementById('velocityLegend');
    const toggleBtn = document.getElementById('loop-toggle');
    const speedSlider = document.getElementById('loop-speed');
    const speedLabel = document.getElementById('loop-speed-label');
    const paceContainer = document.getElementById('paceFeedback');
    
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
    
    const baseAngularSpeed = 2.4; // radians per second for the fastest implementation
    
    const runners = entries.map(([name, lang], index) => {
        const memoryNorm = (lang.stats.memory_avg - minMemory) / memoryRange;
        const cpuNorm = (lang.stats.cpu_avg - minCpu) / cpuRange;
        return {
            name,
            label: formatLanguageName(name),
            color: LANGUAGE_COLORS[name] || '#7b8ba0',
            time: lang.stats.time_avg,
            memory: lang.stats.memory_avg,
            cpu: lang.stats.cpu_avg,
            speed: baseAngularSpeed * (fastest / lang.stats.time_avg),
            size: 8 + memoryNorm * 16,
            trail: 0.4 + cpuNorm * 1.4,
            angle: (index / entries.length) * Math.PI * 2
        };
    });
    
    legend.innerHTML = '';
    if (paceContainer) paceContainer.innerHTML = '';
    const legendData = [...runners].sort((a, b) => a.time - b.time);
    legendData.forEach((runner, index) => {
        const item = document.createElement('div');
        item.className = 'legend-item';
        item.innerHTML = `
            <span class="legend-swatch" style="background:${runner.color}"></span>
            <div>
                    <div class="legend-label">${runner.label}</div>
                    <div class="legend-meta">
                        ${runner.time.toFixed(3)}s • ${runner.cpu?.toFixed(0) ?? '–'}% CPU • ${runner.memory.toFixed(1)} MB
                    </div>
                </div>
        `;
        legend.appendChild(item);
        
        if (paceContainer) {
            const relativeSpeed = fastest / runner.time;
            const widthPercent = Math.max(8, Math.min(100, relativeSpeed * 100));
            const slowerPct = index === 0 ? 0 : ((runner.time - fastest) / fastest) * 100;
            const row = document.createElement('div');
            row.className = 'pace-row';
            row.innerHTML = `
                <div class="pace-label">
                    <span class="pace-rank">#${index + 1}</span>
                    <span>${runner.label}</span>
                </div>
                <div class="pace-track">
                    <div class="pace-fill" style="width:${widthPercent.toFixed(1)}%; background:${runner.color};"></div>
                </div>
                <div class="pace-meta">${index === 0 ? 'Fastest' : '+' + slowerPct.toFixed(0) + '% slower'}</div>
            `;
            paceContainer.appendChild(row);
        }
    });
    
    const ctx = canvas.getContext('2d');
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
    window.addEventListener('resize', resize);
    
    let running = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    let speedMultiplier = 1;
    let lastTime = performance.now();
    
    if (toggleBtn) {
        toggleBtn.textContent = running ? 'Pause Loop' : 'Play Loop';
        toggleBtn.addEventListener('click', () => {
            running = !running;
            toggleBtn.textContent = running ? 'Pause Loop' : 'Play Loop';
        });
    }
    
    if (speedSlider && speedLabel) {
        const updateLabel = () => {
            speedLabel.textContent = `${speedMultiplier.toFixed(1)}x`;
        };
        speedSlider.addEventListener('input', (event) => {
            speedMultiplier = parseFloat(event.target.value);
            updateLabel();
        });
        updateLabel();
    }
    
    function render(timestamp) {
        const now = timestamp || performance.now();
        const delta = Math.min(0.1, (now - lastTime) / 1000);
        lastTime = now;
        const width = canvas.clientWidth;
        const height = canvas.clientHeight;
        const centerX = width / 2;
        const centerY = height / 2;
        const radius = Math.max(120, Math.min(width, height) / 2 - 50);
        
        ctx.clearRect(0, 0, width, height);
        
        // Draw track
        ctx.save();
        ctx.translate(centerX, centerY);
        ctx.strokeStyle = 'rgba(255,255,255,0.15)';
        ctx.lineWidth = 2;
        ctx.setLineDash([6, 10]);
        ctx.beginPath();
        ctx.arc(0, 0, radius, 0, Math.PI * 2);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.restore();
        
        runners.forEach(runner => {
            if (running) {
                runner.angle += delta * runner.speed * speedMultiplier;
                runner.angle %= Math.PI * 2;
            }
            
            const x = centerX + Math.cos(runner.angle) * radius;
            const y = centerY + Math.sin(runner.angle) * radius;
            
            // Trail represents CPU usage
            ctx.beginPath();
            ctx.strokeStyle = hexToRgba(runner.color, 0.6);
            ctx.lineWidth = Math.max(2, runner.size * 0.4);
            ctx.arc(centerX, centerY, radius, runner.angle - runner.trail, runner.angle);
            ctx.stroke();
            
            // Runner
            ctx.save();
            ctx.shadowColor = hexToRgba(runner.color, 0.9);
            ctx.shadowBlur = 15 + runner.trail * 10;
            ctx.fillStyle = runner.color;
            ctx.beginPath();
            ctx.arc(x, y, runner.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
            
            ctx.strokeStyle = 'rgba(255,255,255,0.35)';
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(x, y, runner.size, 0, Math.PI * 2);
            ctx.stroke();
        });
        
        requestAnimationFrame(render);
    }
    
    requestAnimationFrame(render);
}

// Create leaderboard table
function createLeaderboard(languages) {
    const tbody = document.getElementById('leaderboard-body');
    
    const sortedLangs = Object.entries(languages).sort((a, b) => 
        a[1].stats.time_avg - b[1].stats.time_avg
    );
    
    const fastestTime = sortedLangs[0][1].stats.time_avg;
    
    sortedLangs.forEach(([name, lang], index) => {
        const rank = index + 1;
        const multiplier = lang.stats.time_avg / fastestTime;
        
        let speedClass = 'speed-1x';
        let speedText = '1.0x';
        if (multiplier > 1) {
            speedText = multiplier.toFixed(1) + 'x';
            speedClass = multiplier > 5 ? 'speed-very-slow' : 'speed-slow';
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td><span class="rank rank-${rank}">${rank}</span></td>
            <td><span class="language-name">${formatLanguageName(name)}</span></td>
            <td>${lang.stats.time_avg.toFixed(3)}</td>
            <td>${lang.stats.memory_avg.toFixed(2)}</td>
            <td><span class="speed-multiplier ${speedClass}">${speedText}</span></td>
        `;
        tbody.appendChild(row);
    });
}

// Create detailed cards
function createDetailCards(languages) {
    const grid = document.getElementById('details-grid');
    
    const sortedLangs = Object.entries(languages).sort((a, b) => 
        a[1].stats.time_avg - b[1].stats.time_avg
    );
    
    const maxTime = Math.max(...sortedLangs.map(([_, lang]) => lang.stats.time_avg));
    const maxMemory = Math.max(...sortedLangs.map(([_, lang]) => lang.stats.memory_avg));
    
    sortedLangs.forEach(([name, lang], index) => {
        let badge = '';
        let badgeClass = '';
        
        if (index === 0) {
            badge = 'Fastest';
            badgeClass = 'badge-fastest';
        } else if (lang.stats.memory_avg === Math.min(...sortedLangs.map(([_, l]) => l.stats.memory_avg))) {
            badge = 'Most Efficient';
            badgeClass = 'badge-efficient';
        } else if (index < 3) {
            badge = 'Top 3';
            badgeClass = 'badge-good';
        }
        
        const timePercent = (lang.stats.time_avg / maxTime) * 100;
        const memoryPercent = (lang.stats.memory_avg / maxMemory) * 100;
        
        const card = document.createElement('div');
        card.className = 'detail-card';
        card.innerHTML = `
            <div class="detail-header">
                <div class="detail-lang">${formatLanguageName(name)}</div>
                ${badge ? `<div class="detail-badge ${badgeClass}">${badge}</div>` : ''}
            </div>
            <div class="detail-metrics">
                <div>
                    <div class="metric-row">
                        <span class="metric-label">Avg Execution Time</span>
                        <span class="metric-value">${lang.stats.time_avg.toFixed(3)}s</span>
                    </div>
                    <div class="metric-bar">
                        <div class="metric-fill" style="width: ${timePercent}%"></div>
                    </div>
                </div>
                <div>
                    <div class="metric-row">
                        <span class="metric-label">Avg Memory Usage</span>
                        <span class="metric-value">${lang.stats.memory_avg.toFixed(2)} MB</span>
                    </div>
                    <div class="metric-bar">
                        <div class="metric-fill" style="width: ${memoryPercent}%"></div>
                    </div>
                </div>
                <div>
                    <div class="metric-row">
                        <span class="metric-label">Time Range</span>
                        <span class="metric-value">${Math.min(...lang.times).toFixed(3)} - ${Math.max(...lang.times).toFixed(3)}s</span>
                    </div>
                </div>
                <div>
                    <div class="metric-row">
                        <span class="metric-label">Memory Range</span>
                        <span class="metric-value">${Math.min(...lang.memory).toFixed(2)} - ${Math.max(...lang.memory).toFixed(2)} MB</span>
                    </div>
                </div>
            </div>
        `;
        grid.appendChild(card);
    });
}

// Initialize the app
async function init() {
    const data = await loadData();
    
    if (!data) {
        document.body.innerHTML = '<div style="text-align:center;padding:2rem;color:#ff3366;">Error loading benchmark data. Please ensure results.json exists.</div>';
        return;
    }
    
    updateMetadata(data.metadata);
    updateSummary(data.languages);
    createVelocityLoop(data.languages);
    createTimeChart(data.languages);
    createMemoryChart(data.languages);
    createLeaderboard(data.languages);
    createDetailCards(data.languages);
}

// Start when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
