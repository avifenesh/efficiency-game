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
