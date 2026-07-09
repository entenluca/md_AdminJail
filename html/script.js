const adminMenu = document.getElementById('adminMenu');
const jailHud = document.getElementById('jailHud');
const minigame = document.getElementById('minigame');
const playerList = document.getElementById('playerList');
const jailCount = document.getElementById('jailCount');
const closeBtn = document.getElementById('closeBtn');
const adminSearch = document.getElementById('adminSearch');
const activeListLabel = document.getElementById('activeListLabel');
const tabButtons = document.querySelectorAll('.tab');

const jailPopup = document.getElementById('jailPopup');
const modalEyebrow = document.getElementById('modalEyebrow');
const modalTitle = document.getElementById('modalTitle');
const selectedPlayerBox = document.querySelector('.selected-player');
const popupPlayerName = document.getElementById('popupPlayerName');
const popupPlayerId = document.getElementById('popupPlayerId');
const popupReason = document.getElementById('popupReason');
const popupAmount = document.getElementById('popupAmount');
const popupAmountLabel = document.getElementById('popupAmountLabel');
const popupReasonCheck = document.getElementById('popupReasonCheck');
const popupAmountCheck = document.getElementById('popupAmountCheck');
const popupCancelBtn = document.getElementById('popupCancelBtn');
const popupReleaseBtn = document.getElementById('popupReleaseBtn');
const popupStartBtn = document.getElementById('popupStartBtn');
const amountIcon = document.getElementById('amountIcon');
const typeButtons = document.querySelectorAll('.type-card');
const dialogActions = document.querySelector('.dialog-actions');

const jailTitle = document.getElementById('jailTitle');
const jailTypeText = document.getElementById('jailTypeText');
const jailAdminName = document.getElementById('jailAdminName');
const jailReasonText = document.getElementById('jailReasonText');
const jailValueLabel = document.getElementById('jailValueLabel');
const jailValueText = document.getElementById('jailValueText');

const minigameGrid = document.getElementById('minigameGrid');
const minigameTimer = document.getElementById('minigameTimer');
const minigameProgress = document.getElementById('minigameProgress');

const ICONS = {
    clock: '<circle cx="12" cy="12" r="8" stroke="currentColor" stroke-width="1.6"/><path d="M12 8v4l3 2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>',
    broom: '<path d="M9 20l-2-8M15 20l2-8M7 12h10" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><path d="M12 4v4" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>',
    toilet: '<path d="M8 10h8v10H8z" stroke="currentColor" stroke-width="1.6"/><path d="M10 6h4v4h-4zM6 20h12" stroke="currentColor" stroke-width="1.6"/>',
    jail: '<rect x="5" y="10" width="14" height="10" rx="2" stroke="currentColor" stroke-width="1.6"/><path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.6"/>',
    edit: '<path d="M4 16l2-6 6-2 8 8-6 2-2 6-8-8z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>'
};

let permissions = { jail: true, unjail: true, edit: true };
let jailTypes = {};
let onlinePlayers = [];
let jailedPlayers = [];
let activeTab = 'players';
let selectedPlayer = null;
let selectedType = 'standard';
let popupMode = 'create';
let minigameInterval = null;
let minigameConfig = null;
let cleanedSpots = 0;

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function getType(typeKey) {
    return jailTypes[typeKey] || {};
}

function usesTime(typeKey) {
    return getType(typeKey).usesTime === true || typeKey === 'standard';
}

function formatClock(totalSeconds) {
    const seconds = Math.max(Number(totalSeconds) || 0, 0);
    const minutes = Math.floor(seconds / 60);
    const rest = seconds % 60;
    return `${String(minutes).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
}

function formatHudTitle(data) {
    if (data.remainingSeconds !== undefined) {
        const minutes = Math.max(Math.ceil((data.remainingSeconds || 0) / 60), 0);
        const label = minutes === 1 ? 'MINUTE' : 'MINUTEN';
        return `ADMINJAIL: ${minutes} ${label}`;
    }

    return `ADMINJAIL: ${data.tasksCompleted || 0}/${data.tasksRequired || 0} AUFGABEN`;
}

function setSquareState(button, valid) {
    button.classList.toggle('success', valid);
    button.classList.toggle('danger', !valid);
    button.textContent = valid ? '✓' : '×';
}

function validatePopup() {
    if (popupMode === 'edit') {
        setSquareState(popupReasonCheck, true);
        setSquareState(popupAmountCheck, Number(popupAmount.value) > 0);
        return;
    }

    setSquareState(popupReasonCheck, popupReason.value.trim().length > 0);
    setSquareState(popupAmountCheck, Number(popupAmount.value) > 0);
}

function setAmountIcon(typeKey) {
    let iconKey = 'broom';

    if (usesTime(typeKey)) {
        iconKey = 'clock';
    } else if (typeKey === 'facility') {
        iconKey = 'toilet';
    }

    amountIcon.innerHTML = ICONS[iconKey];
}

function setSelectedType(typeKey) {
    selectedType = typeKey;

    typeButtons.forEach((button) => {
        button.classList.toggle('active', button.dataset.type === selectedType);
    });

    const isTime = usesTime(selectedType);
    popupAmountLabel.textContent = isTime ? 'Zeit (Minuten)' : 'Anzahl Aufgaben';
    setAmountIcon(selectedType);
    validatePopup();
}

function normalizePlayer(player) {
    const id = Number(player.id || player.source || 0);
    const jailedData = jailedPlayers.find((entry) => Number(entry.id) === id);

    return {
        ...player,
        id,
        name: player.name || `Spieler ${id}`,
        isJailed: player.isJailed === true || Boolean(jailedData),
        jailType: player.jailType || (jailedData && jailedData.jailType) || 'standard',
        jailTypeLabel: player.jailTypeLabel || (jailedData && jailedData.jailTypeLabel) || 'Standard Jail',
        penalty: player.penalty || (jailedData && jailedData.penalty) || '',
        reason: player.reason || (jailedData && jailedData.reason) || '',
        admin: player.admin || (jailedData && jailedData.admin) || '',
        amount: player.amount || (jailedData && jailedData.amount) || undefined
    };
}

function setActiveTab(tabName) {
    activeTab = tabName;
    tabButtons.forEach((button) => button.classList.toggle('active', button.dataset.tab === activeTab));
    activeListLabel.textContent = activeTab === 'jailed' ? 'Inhaftierte Spieler' : 'Spielerliste';
    renderList();
}

function getVisiblePlayers() {
    const search = adminSearch.value.trim().toLowerCase();
    const source = activeTab === 'jailed' ? jailedPlayers : onlinePlayers;

    return source.map(normalizePlayer).filter((player) => {
        if (!search) return true;

        return String(player.id).includes(search)
            || String(player.name).toLowerCase().includes(search)
            || String(player.reason || '').toLowerCase().includes(search)
            || String(player.admin || '').toLowerCase().includes(search);
    });
}

function createActionIcon(jailed) {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('fill', 'none');

    if (jailed) {
        svg.innerHTML = ICONS.edit;
    } else {
        svg.innerHTML = ICONS.jail;
    }

    return svg;
}

function renderList() {
    const visible = getVisiblePlayers();
    playerList.innerHTML = '';
    jailCount.textContent = String(visible.length);

    if (visible.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'empty-list';
        empty.textContent = activeTab === 'jailed'
            ? 'Keine Spieler im AdminJail'
            : 'Keine Spieler gefunden';
        playerList.appendChild(empty);
        return;
    }

    visible.forEach((player) => {
        const row = document.createElement('article');
        row.className = 'player-row';

        const main = document.createElement('div');
        main.className = 'player-main';

        const avatar = document.createElement('div');
        avatar.className = `player-avatar ${player.isJailed ? 'jailed' : ''}`;
        avatar.innerHTML = '<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.6"/><path d="M5 20c0-4 3.5-6 7-6s7 2 7 6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';

        const info = document.createElement('div');
        info.className = 'player-info';

        const name = document.createElement('strong');
        name.textContent = player.name;

        const meta = document.createElement('small');
        meta.textContent = player.isJailed
            ? `${player.jailTypeLabel} · ${player.penalty}`
            : 'Online';

        info.appendChild(name);
        info.appendChild(meta);

        main.appendChild(avatar);
        main.appendChild(info);

        const id = document.createElement('div');
        id.className = 'player-id';
        id.textContent = String(player.id);

        const action = document.createElement('button');
        action.type = 'button';
        action.className = `row-action ${player.isJailed ? 'jailed' : ''}`;
        action.title = player.isJailed ? 'Strafe bearbeiten / freilassen' : 'Spieler inhaftieren';
        action.disabled = (!player.isJailed && !permissions.jail)
            || (player.isJailed && !permissions.edit && !permissions.unjail);
        action.appendChild(createActionIcon(player.isJailed));
        action.addEventListener('click', () => {
            openJailPopup(player, player.isJailed ? 'edit' : 'create');
        });

        row.appendChild(main);
        row.appendChild(id);
        row.appendChild(action);
        playerList.appendChild(row);
    });
}

function openJailPopup(player, mode = 'create') {
    selectedPlayer = normalizePlayer(player);
    popupMode = mode;

    selectedPlayerBox.classList.add('visible');
    popupPlayerName.textContent = selectedPlayer.name;
    popupPlayerId.textContent = String(selectedPlayer.id);

    modalEyebrow.textContent = mode === 'edit' ? 'Strafe bearbeiten' : 'Neue Strafe';
    modalTitle.textContent = mode === 'edit' ? selectedPlayer.name : 'Spieler bestrafen';

    popupReason.disabled = mode === 'edit';
    popupReason.value = mode === 'edit' ? selectedPlayer.reason : '';
    popupAmount.value = mode === 'edit' ? (selectedPlayer.amount || '') : '';
    popupAmount.dataset.manual = mode === 'edit' ? '1' : '';

    typeButtons.forEach((button) => {
        button.disabled = mode === 'edit';
    });

    popupReleaseBtn.classList.toggle('hidden', mode !== 'edit' || !permissions.unjail);
    dialogActions.classList.toggle('has-release', mode === 'edit' && permissions.unjail);
    popupStartBtn.textContent = mode === 'edit' ? 'Speichern' : 'Strafe starten';

    setSelectedType(mode === 'edit' ? selectedPlayer.jailType : 'standard');
    validatePopup();
    jailPopup.classList.remove('hidden');
    setTimeout(() => (mode === 'edit' ? popupAmount : popupReason).focus(), 0);
}

function closeJailPopup() {
    jailPopup.classList.add('hidden');
    selectedPlayer = null;
    popupMode = 'create';
    popupReason.disabled = false;
    typeButtons.forEach((button) => { button.disabled = false; });
}

function submitPopup() {
    if (!selectedPlayer) return;

    const amount = Number(popupAmount.value);
    const reason = popupReason.value.trim();

    if (popupMode === 'edit') {
        if (amount > 0 && permissions.edit) {
            post('editJail', { id: selectedPlayer.id, amount });
            closeJailPopup();
        } else {
            validatePopup();
        }
        return;
    }

    if (!permissions.jail || !reason || amount < 1) {
        validatePopup();
        return;
    }

    post('createJail', {
        id: selectedPlayer.id,
        jailType: selectedType,
        amount,
        reason
    });
    closeJailPopup();
}

function releaseSelected() {
    if (!selectedPlayer || !permissions.unjail) return;
    post('releaseJail', { id: selectedPlayer.id });
    closeJailPopup();
}

function openMenu(data) {
    permissions = data.permissions || permissions;
    jailTypes = data.jailTypes || {};
    jailedPlayers = (data.players || []).map((player) => ({ ...player, isJailed: true }));

    if (Array.isArray(data.onlinePlayers) && data.onlinePlayers.length > 0) {
        onlinePlayers = data.onlinePlayers;
    } else {
        onlinePlayers = jailedPlayers;
    }

    onlinePlayers = onlinePlayers.map(normalizePlayer).sort((a, b) => Number(a.id) - Number(b.id));
    jailedPlayers = jailedPlayers.map(normalizePlayer).sort((a, b) => Number(a.id) - Number(b.id));

    setActiveTab('players');
    adminMenu.classList.remove('hidden');
    closeJailPopup();
    renderList();
}

function closeMenu() {
    adminMenu.classList.add('hidden');
    closeJailPopup();
    adminSearch.value = '';
}

function showJailHud(data) {
    jailHud.classList.remove('hidden');
    updateJailHud(data);
}

function updateJailHud(data) {
    if (jailHud.classList.contains('hidden')) {
        jailHud.classList.remove('hidden');
    }

    jailTitle.textContent = formatHudTitle(data);
    jailTypeText.textContent = data.jailType || 'Standard Jail';
    jailAdminName.textContent = data.admin || 'Unbekannt';
    jailReasonText.textContent = data.reason || '-';

    if (data.remainingSeconds !== undefined) {
        const seconds = Math.max(Number(data.remainingSeconds) || 0, 0);
        jailValueLabel.textContent = 'Restzeit';
        jailValueText.textContent = `${formatClock(seconds)} · ${Math.max(Math.ceil(seconds / 60), 0)} Min`;
    } else {
        const done = Number(data.tasksCompleted) || 0;
        const required = Number(data.tasksRequired) || 0;
        const remaining = Math.max(required - done, 0);
        jailValueLabel.textContent = 'Aufgaben';
        jailValueText.textContent = `${remaining} offen · ${required} gesamt`;
    }
}

function hideJailHud() {
    jailHud.classList.add('hidden');
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
        spot.textContent = isDirty ? '🧽' : '✨';
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
adminSearch.addEventListener('input', renderList);
popupReason.addEventListener('input', validatePopup);
popupAmount.addEventListener('input', () => {
    popupAmount.dataset.manual = '1';
    validatePopup();
});
popupCancelBtn.addEventListener('click', closeJailPopup);
popupStartBtn.addEventListener('click', submitPopup);
popupReleaseBtn.addEventListener('click', releaseSelected);

tabButtons.forEach((button) => {
    button.addEventListener('click', () => setActiveTab(button.dataset.tab));
});

typeButtons.forEach((button) => {
    button.addEventListener('click', () => setSelectedType(button.dataset.type));
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (!jailPopup.classList.contains('hidden')) {
            closeJailPopup();
            return;
        }

        if (!adminMenu.classList.contains('hidden')) {
            post('closeMenu');
        }
    }
});
