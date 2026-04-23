const app = document.getElementById('app');
const creatorView = document.getElementById('creator-view');
const spawnView = document.getElementById('spawn-view');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'openCreator') {
        app.classList.remove('hidden');
        creatorView.classList.remove('hidden');
        spawnView.classList.add('hidden');
    }

    if (data.type === 'openSpawnPicker') {
        creatorView.classList.add('hidden');
        spawnView.classList.remove('hidden');
    }
});

// Gnero
document.querySelectorAll('.gender-selector button').forEach(btn => {
    btn.onclick = () => {
        document.querySelector('.gender-selector button.active').classList.remove('active');
        btn.classList.add('active');
        fetchNUI('changeGender', { gender: btn.dataset.gender });
    };
});

// Update em tempo real nos inputs
const inputs = ['father', 'mother', 'shapeMix', 'hair', 'hairColor', 'eyes', 'tops', 'legs', 'shoes'];
inputs.forEach(id => {
    const el = document.getElementById(id);
    el.oninput = () => {
        updateCharacter();
    };
});

function updateCharacter() {
    const data = {};
    inputs.forEach(id => {
        data[id] = parseInt(document.getElementById(id).value);
    });
    fetchNUI('updateCharacter', data);
}

// Finalizar Criao
document.getElementById('btn-finalize').onclick = () => {
    fetchNUI('finalize', {});
};

// Seleo de Spawn
document.querySelectorAll('.spawn-card').forEach(card => {
    card.onclick = () => {
        const charData = { gender: document.querySelector('.gender-selector button.active').dataset.gender };
        inputs.forEach(id => { charData[id] = parseInt(document.getElementById(id).value); });

        fetchNUI('selectSpawn', { 
            location: card.dataset.loc,
            charData: charData
        });
        app.classList.add('hidden');
    };
});

function fetchNUI(eventName, data) {
    return fetch(`https://${GetParentResourceName()}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}
