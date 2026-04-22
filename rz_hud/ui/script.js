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
    }
});
