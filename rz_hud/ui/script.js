let lastValues = {
    street: '',
    zone: '',
    time: '',
    assalto: null,
    speed: null,
    inVehicle: null,
    health: null,
    armor: null
};

window.addEventListener('message', (event) => {
    let data = event.data;

    if (data.type === 'updateHUD') {
        const hudUpdate = () => {
            // Atualizar Localizao (Apenas se mudar)
            if (data.street !== lastValues.street) {
                document.getElementById('street-text').innerText = data.street || 'DESCONHECIDO';
                lastValues.street = data.street;
            }
            if (data.zone !== lastValues.zone) {
                document.getElementById('zone-text').innerText = data.zone || 'CALIFÓRNIA';
                lastValues.zone = data.zone;
            }

            // Atualizar Horrio
            if (data.time !== lastValues.time) {
                document.getElementById('game-time').innerText = data.time;
                lastValues.time = data.time;
            }

            // Atualizar Badge de Assalto
            if (data.assalto !== lastValues.assalto) {
                const assaltoBadge = document.getElementById('assalto-badge');
                if (data.assalto) {
                    assaltoBadge.classList.remove('hidden');
                } else {
                    assaltoBadge.classList.add('hidden');
                }
                lastValues.assalto = data.assalto;
            }

            // Atualizar Estado de Veculo
            if (data.inVehicle !== lastValues.inVehicle) {
                const speedContainer = document.getElementById('speed-container');
                const seatbeltRow = document.getElementById('seatbelt-row');
                
                if (data.inVehicle) {
                    speedContainer.classList.remove('hidden');
                    seatbeltRow.classList.remove('hidden');
                } else {
                    speedContainer.classList.add('hidden');
                    seatbeltRow.classList.add('hidden');
                }
                lastValues.inVehicle = data.inVehicle;
            }

            // Atualizar Velocidade
            if (data.inVehicle && data.speed !== lastValues.speed) {
                document.getElementById('speed-value').innerText = data.speed;
                lastValues.speed = data.speed;
            }

            // Atualizar Status (Vida e Colete)
            if (data.health !== lastValues.health) {
                document.getElementById('health-fill').style.width = data.health + '%';
                lastValues.health = data.health;
            }
            if (data.armor !== lastValues.armor) {
                document.getElementById('armor-fill').style.width = data.armor + '%';
                lastValues.armor = data.armor;
            }
        };

        // Executar com requestAnimationFrame para sincronizar com o browser
        requestAnimationFrame(hudUpdate);
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

    setTimeout(() => {
        postIt.classList.add('out');
        setTimeout(() => {
            postIt.remove();
        }, 400);
    }, 3000);
}
