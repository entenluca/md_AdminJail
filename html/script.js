const app = document.getElementById('app');
const jailHud = document.getElementById('jailHud');
const jailAdminName = document.getElementById('jailAdminName');
const jailTimeValue = document.getElementById('jailTimeValue');
const jailReasonText = document.getElementById('jailReasonText');
const playerTableBody = document.getElementById('playerTableBody');
const jailCount = document.getElementById('jailCount');
const closeBtn = document.getElementById('closeBtn');
const refreshBtn = document.getElementById('refreshBtn');

let jailHudTimeout = null;

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

function formatTime(totalSeconds) {
    const seconds = Math.max(totalSeconds, 0);
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }

    return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function showJailHud(data) {
    if (jailHudTimeout) {
        clearTimeout(jailHudTimeout);
        jailHudTimeout = null;
    }

    jailHud.classList.remove('hiding', 'hidden');
    jailAdminName.textContent = data.admin || 'Unbekannt';
    jailReasonText.textContent = data.reason || '-';
    jailTimeValue.textContent = formatTime(data.remainingSeconds || 0);
}

function updateJailHud(data) {
    if (jailHud.classList.contains('hidden')) {
        showJailHud(data);
        return;
    }

    jailTimeValue.textContent = formatTime(data.remainingSeconds || 0);

    if (data.admin) {
        jailAdminName.textContent = data.admin;
    }

    if (data.reason) {
        jailReasonText.textContent = data.reason;
    }
}

function hideJailHud() {
    if (jailHud.classList.contains('hidden')) {
        return;
    }

    jailHud.classList.add('hiding');

    if (jailHudTimeout) {
        clearTimeout(jailHudTimeout);
    }

    jailHudTimeout = setTimeout(() => {
        jailHud.classList.add('hidden');
        jailHud.classList.remove('hiding');
        jailHudTimeout = null;
    }, 320);
}

function renderPlayers(players) {
    playerTableBody.innerHTML = '';

    if (!players || players.length === 0) {
        const row = document.createElement('tr');
        row.className = 'empty-row';
        row.innerHTML = '<td colspan="6">Keine Spieler im AdminJail</td>';
        playerTableBody.appendChild(row);
        jailCount.textContent = '0';
        return;
    }

    jailCount.textContent = String(players.length);

    players.forEach((player) => {
        const row = document.createElement('tr');

        row.innerHTML = `
            <td>${player.id}</td>
            <td>${escapeHtml(player.name)}</td>
            <td><span class="minutes-badge">${player.minutes} Min</span></td>
            <td class="reason-cell" title="${escapeHtml(player.reason)}">${escapeHtml(player.reason)}</td>
            <td>${escapeHtml(player.admin)}</td>
            <td><button class="btn-unjail" data-id="${player.id}">Freilassen</button></td>
        `;

        playerTableBody.appendChild(row);
    });

    document.querySelectorAll('.btn-unjail').forEach((button) => {
        button.addEventListener('click', () => {
            post('unjailPlayer', { id: Number(button.dataset.id) });
        });
    });
}

function escapeHtml(value) {
    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        app.classList.remove('hidden');
        renderPlayers(data.players || []);
    }

    if (data.action === 'close') {
        app.classList.add('hidden');
    }

    if (data.action === 'showJailHud') {
        showJailHud(data);
    }

    if (data.action === 'updateJailHud') {
        updateJailHud(data);
    }

    if (data.action === 'hideJailHud') {
        hideJailHud();
    }
});

closeBtn.addEventListener('click', () => post('closePanel'));
refreshBtn.addEventListener('click', () => post('refreshPanel'));

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('closePanel');
    }
});
