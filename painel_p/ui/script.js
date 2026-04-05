const app = new Vue({
    el: '#app',
    data: {
        visible: false,
        tab: 'home',
        playerRank: 'Player',
        search: '',
        players: [],
        vehicles: [],
        objects: []
    },
    computed: {
        filteredPlayers() {
            if (!this.search) return this.players;
            return this.players.filter(p => {
                return p.name.toLowerCase().includes(this.search.toLowerCase()) || p.id.toString().includes(this.search);
            });
        }
    },
    methods: {
        closeMenu() {
            this.visible = false;
            fetch(`https://painel_p/close`, {
                method: 'POST',
                body: JSON.stringify({})
            });
        },
        action(id, type, extra) {
            fetch(`https://painel_p/adminAction`, {
                method: 'POST',
                body: JSON.stringify({ id: id, action: type, extra: extra })
            });
        },
        selfAction(type) {
            fetch(`https://painel_p/selfAction`, {
                method: 'POST',
                body: JSON.stringify({ action: type })
            });
        },
        spawnVehicle(model) {
            fetch(`https://painel_p/spawnVehicle`, {
                method: 'POST',
                body: JSON.stringify({ model: model })
            });
        },
        spawnObject(model) {
            fetch(`https://painel_p/spawnObject`, {
                method: 'POST',
                body: JSON.stringify({ model: model })
            });
        },
        setRank(id, event) {
            const rank = event.target.value;
            if (rank) {
                this.action(id, 'setrank', rank);
                event.target.value = ''; // Reset select
            }
        }
    }
});

// Listener para mensagens do Lua
window.addEventListener('message', (event) => {
    let data = event.data;
    if (data.type === 'show') {
        app.visible = data.status;
        app.playerRank = data.rank;
        app.players = data.players;
        app.vehicles = data.vehicles;
        app.objects = data.objects;
    }
});

// Fechar com ESC
document.onkeyup = function (data) {
    if (data.which == 27) { // ESC Key
        app.closeMenu();
    }
};
