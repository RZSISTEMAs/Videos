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
        if (data.inVehicle) {
            speedContainer.classList.remove('hidden');
            speedText.innerText = data.speed;
        } else {
            speedContainer.classList.add('hidden');
        }

        // Atualizar Status (Vida e Colete) - SEMPRE VISÍVEL
        const healthBar = document.getElementById('health-fill');
        const armorBar = document.getElementById('armor-fill');
        
        healthBar.style.width = data.health + '%';
        armorBar.style.width = data.armor + '%';
    }
});
