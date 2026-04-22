window.addEventListener('message', (event) => {
    let data = event.data;

    if (data.type === 'updateHUD') {
        // Atualizar Localizao
        document.getElementById('street-text').innerText = data.street || 'DESCONHECIDO';
        document.getElementById('zone-text').innerText = data.zone || 'CALIFÓRNIA';

        // Atualizar Horrio
        document.getElementById('game-time').innerText = data.time;

        // Atualizar Badge de Assalto
        const assaltoBadge = document.getElementById('assalto-badge');
        if (data.assalto) {
            assaltoBadge.classList.remove('hidden');
        } else {
            assaltoBadge.classList.add('hidden');
        }

        // Atualizar Velocidade
        const speedContainer = document.getElementById('speed-container');
        const speedText = document.getElementById('speed-value');
        const seatbeltRow = document.getElementById('seatbelt-row');

        if (data.inVehicle) {
            speedContainer.classList.remove('hidden');
            speedText.innerText = data.speed;
            seatbeltRow.classList.remove('hidden'); // Mostra cinto no carro
        } else {
            speedContainer.classList.add('hidden');
            seatbeltRow.classList.add('hidden'); // Esconde fora do carro
        }

        // Atualizar Status (Vida e Colete)
        const healthBar = document.getElementById('health-fill');
        const armorBar = document.getElementById('armor-fill');
        
        healthBar.style.width = data.health + '%';
        armorBar.style.width = data.armor + '%';
    }

    if (data.type === 'updateSeatbelt') {
        const icon = document.getElementById('seatbelt-icon');
        const text = document.getElementById('seatbelt-text');
        if (data.status) {
            icon.classList.remove('off');
            icon.classList.add('on');
            icon.innerText = '🔐';
            text.innerText = 'CINTO COLOCADO';
            text.style.color = '#10b981';
        } else {
            icon.classList.remove('on');
            icon.classList.add('off');
            icon.innerText = '🔏';
            text.innerText = 'CINTO SOLTO';
            text.style.color = '#ff9d00';
        }
    }

    if (data.type === 'notify') {
        showPostIt(data.message);
    }
});

function showPostIt(message) {
    const container = document.getElementById('notify-container');
    const postIt = document.createElement('div');
    postIt.className = 'post-it';
    postIt.innerText = message;

    container.appendChild(postIt);

    // Remover aps 3 segundos
    setTimeout(() => {
        postIt.classList.add('out');
        setTimeout(() => {
            postIt.remove();
        }, 500);
    }, 3000);
}
