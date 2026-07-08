const app = document.getElementById('app');
const playerTableBody = document.getElementById('playerTableBody');
const jailCount = document.getElementById('jailCount');
const closeBtn = document.getElementById('closeBtn');
const refreshBtn = document.getElementById('refreshBtn');

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
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
});

closeBtn.addEventListener('click', () => post('closePanel'));
refreshBtn.addEventListener('click', () => post('refreshPanel'));

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('closePanel');
    }
});
