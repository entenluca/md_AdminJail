const adminMenu = document.getElementById('adminMenu');
const jailHud = document.getElementById('jailHud');
const minigame = document.getElementById('minigame');
const playerTableBody = document.getElementById('playerTableBody');
const jailCount = document.getElementById('jailCount');
const closeBtn = document.getElementById('closeBtn');
const refreshBtn = document.getElementById('refreshBtn');
const jailForm = document.getElementById('jailForm');
const formMode = document.getElementById('formMode');
const formTitle = document.getElementById('formTitle');
const playerIdInput = document.getElementById('playerId');
const jailTypeSelect = document.getElementById('jailType');
const amountInput = document.getElementById('amount');
const amountLabel = document.getElementById('amountLabel');
const reasonInput = document.getElementById('reason');
const submitBtn = document.getElementById('submitBtn');
const cancelEditBtn = document.getElementById('cancelEditBtn');
const jailTitle = document.getElementById('jailTitle');
const jailTypeText = document.getElementById('jailTypeText');
const jailAdminName = document.getElementById('jailAdminName');
const jailReasonText = document.getElementById('jailReasonText');
const minigameGrid = document.getElementById('minigameGrid');
const minigameTimer = document.getElementById('minigameTimer');
const minigameProgress = document.getElementById('minigameProgress');

let permissions = { jail: true, unjail: true, edit: true };
let jailTypes = {};
let minigameInterval = null;
let minigameConfig = null;
let cleanedSpots = 0;

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
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

function formatJailTitle(data) {
    if (data.remainingSeconds !== undefined) {
        const minutes = Math.max(Math.ceil((data.remainingSeconds || 0) / 60), 0);
        const label = minutes === 1 ? 'MINUTE' : 'MINUTEN';
        return `ADMINJAIL: ${minutes} ${label}`;
    }

    return `ADMINJAIL: ${data.tasksCompleted || 0}/${data.tasksRequired || 0} AUFGABEN`;
}

function showJailHud(data) {
    jailHud.classList.remove('hidden');
    jailTitle.textContent = formatJailTitle(data);
    jailTypeText.textContent = data.jailType || 'Standard Jail';
    jailAdminName.textContent = data.admin || 'Unbekannt';
    jailReasonText.textContent = data.reason || '-';
}

function updateJailHud(data) {
    if (jailHud.classList.contains('hidden')) {
        showJailHud(data);
        return;
    }

    jailTitle.textContent = formatJailTitle(data);
    jailTypeText.textContent = data.jailType || jailTypeText.textContent;
    if (data.admin) jailAdminName.textContent = data.admin;
    if (data.reason) jailReasonText.textContent = data.reason;
}

function hideJailHud() {
    jailHud.classList.add('hidden');
}

function populateJailTypes(types) {
    jailTypeSelect.innerHTML = '';
    Object.entries(types).forEach(([key, value]) => {
        const option = document.createElement('option');
        option.value = key;
        option.textContent = value.label;
        option.dataset.usesTime = value.usesTime ? '1' : '0';
        option.dataset.defaultAmount = value.defaultAmount || 10;
        jailTypeSelect.appendChild(option);
    });
    updateAmountLabel();
}

function updateAmountLabel() {
    const selected = jailTypeSelect.selectedOptions[0];
    if (!selected) return;

    const usesTime = selected.dataset.usesTime === '1';
    amountLabel.textContent = usesTime ? 'Zeit (Minuten)' : 'Anzahl Aufgaben';

    if (formMode.value === 'create' && !amountInput.dataset.manual) {
        amountInput.value = selected.dataset.defaultAmount;
    }
}

function resetForm() {
    formMode.value = 'create';
    formTitle.textContent = 'Neue Strafe';
    submitBtn.textContent = 'Strafe setzen';
    cancelEditBtn.classList.add('hidden');
    playerIdInput.disabled = false;
    jailTypeSelect.disabled = false;
    reasonInput.disabled = false;
    jailForm.reset();
    amountInput.dataset.manual = '';
    updateAmountLabel();
}

function startEdit(player) {
    formMode.value = 'edit';
    formTitle.textContent = `Strafe bearbeiten: ${player.name}`;
    submitBtn.textContent = 'Strafe speichern';
    cancelEditBtn.classList.remove('hidden');
    playerIdInput.value = player.id;
    playerIdInput.disabled = true;
    jailTypeSelect.value = player.jailType;
    jailTypeSelect.disabled = true;
    amountInput.value = player.amount;
    amountInput.dataset.manual = '1';
    reasonInput.value = player.reason;
    reasonInput.disabled = true;
    updateAmountLabel();
}

function renderPlayers(players) {
    playerTableBody.innerHTML = '';

    if (!players || players.length === 0) {
        const row = document.createElement('tr');
        row.className = 'empty-row';
        row.innerHTML = '<td colspan="7">Keine aktiven Jails</td>';
        playerTableBody.appendChild(row);
        jailCount.textContent = '0';
        return;
    }

    jailCount.textContent = String(players.length);

    players.forEach((player) => {
        const row = document.createElement('tr');
        const typeClass = `type-${player.jailType}`;

        row.innerHTML = `
            <td>${player.id}</td>
            <td>${escapeHtml(player.name)}</td>
            <td><span class="type-pill ${typeClass}">${escapeHtml(player.jailTypeLabel)}</span></td>
            <td>${escapeHtml(player.penalty)}</td>
            <td>${escapeHtml(player.reason)}</td>
            <td>${escapeHtml(player.admin)}</td>
            <td class="actions-cell"></td>
        `;

        const actions = row.querySelector('.actions-cell');

        if (permissions.edit) {
            const editBtn = document.createElement('button');
            editBtn.className = 'btn btn-small btn-edit';
            editBtn.textContent = 'Bearbeiten';
            editBtn.addEventListener('click', () => startEdit(player));
            actions.appendChild(editBtn);
        }

        if (permissions.unjail) {
            const releaseBtn = document.createElement('button');
            releaseBtn.className = 'btn btn-small btn-release';
            releaseBtn.textContent = 'Freilassen';
            releaseBtn.addEventListener('click', () => post('releaseJail', { id: player.id }));
            actions.appendChild(releaseBtn);
        }

        playerTableBody.appendChild(row);
    });
}

function openMenu(data) {
    permissions = data.permissions || permissions;
    jailTypes = data.jailTypes || {};
    populateJailTypes(jailTypes);
    renderPlayers(data.players || []);
    adminMenu.classList.remove('hidden');
}

function closeMenu() {
    adminMenu.classList.add('hidden');
    resetForm();
}

function stopMinigameTimer() {
    if (minigameInterval) {
        clearInterval(minigameInterval);
        minigameInterval = null;
    }
}

function finishMinigame(success) {
    stopMinigameTimer();
    minigame.classList.add('hidden');
    minigameGrid.innerHTML = '';
    post('minigameResult', { success });
}

function openMinigame(config) {
    minigameConfig = config || { spots: 6, timeLimit: 12, requiredCleans: 5 };
    cleanedSpots = 0;
    minigameGrid.innerHTML = '';
    minigame.classList.remove('hidden');

    let timeLeft = minigameConfig.timeLimit;
    minigameTimer.textContent = `${timeLeft}s`;
    minigameProgress.textContent = `0/${minigameConfig.requiredCleans}`;

    const dirtyIndexes = [];
    while (dirtyIndexes.length < minigameConfig.requiredCleans) {
        const index = Math.floor(Math.random() * minigameConfig.spots);
        if (!dirtyIndexes.includes(index)) dirtyIndexes.push(index);
    }

    for (let i = 0; i < minigameConfig.spots; i += 1) {
        const spot = document.createElement('button');
        spot.type = 'button';
        const isDirty = dirtyIndexes.includes(i);
        spot.className = `minigame-spot ${isDirty ? 'dirty' : 'clean'}`;
        spot.textContent = isDirty ? '🦠' : '✨';
        spot.disabled = !isDirty;

        if (isDirty) {
            spot.addEventListener('click', () => {
                spot.className = 'minigame-spot clean';
                spot.textContent = '✨';
                spot.disabled = true;
                cleanedSpots += 1;
                minigameProgress.textContent = `${cleanedSpots}/${minigameConfig.requiredCleans}`;

                if (cleanedSpots >= minigameConfig.requiredCleans) {
                    finishMinigame(true);
                }
            });
        }

        minigameGrid.appendChild(spot);
    }

    stopMinigameTimer();
    minigameInterval = setInterval(() => {
        timeLeft -= 1;
        minigameTimer.textContent = `${timeLeft}s`;

        if (timeLeft <= 0) {
            finishMinigame(cleanedSpots >= minigameConfig.requiredCleans);
        }
    }, 1000);
}

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openMenu':
            openMenu(data);
            break;
        case 'closeMenu':
            closeMenu();
            break;
        case 'showJailHud':
            showJailHud(data);
            break;
        case 'updateJailHud':
            updateJailHud(data);
            break;
        case 'hideJailHud':
            hideJailHud();
            break;
        case 'openMinigame':
            openMinigame(data.config);
            break;
        case 'closeMinigame':
            stopMinigameTimer();
            minigame.classList.add('hidden');
            break;
        default:
            break;
    }
});

closeBtn.addEventListener('click', () => post('closeMenu'));
refreshBtn.addEventListener('click', () => post('refreshMenu'));
cancelEditBtn.addEventListener('click', resetForm);
jailTypeSelect.addEventListener('change', updateAmountLabel);
amountInput.addEventListener('input', () => {
    amountInput.dataset.manual = '1';
});

jailForm.addEventListener('submit', (event) => {
    event.preventDefault();

    const payload = {
        id: Number(playerIdInput.value),
        jailType: jailTypeSelect.value,
        amount: Number(amountInput.value),
        reason: reasonInput.value.trim()
    };

    if (formMode.value === 'edit') {
        post('editJail', { id: payload.id, amount: payload.amount });
    } else if (permissions.jail) {
        post('createJail', payload);
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (!adminMenu.classList.contains('hidden')) {
            post('closeMenu');
        }
    }
});
