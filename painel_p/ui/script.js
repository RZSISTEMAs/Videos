const app = new Vue({
    el: '#app',
    data: {
        visible: false,
        tab: 'home',
        playerRank: 'Player',
        search: '',
        players: [
            {id: 1, name: 'Richard', ping: 25}
        ]
    },
    computed: {
        filteredPlayers() {
            return this.players.filter(p => {
                return p.name.toLowerCase().includes(this.search.toLowerCase()) || p.id.toString().includes(this.search);
            });
        }
    },
    methods: {
        closeMenu() {
            this.visible = false;
            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                body: JSON.stringify({})
            });
        },
        action(id, type) {
            fetch(`https://${GetParentResourceName()}/adminAction`, {
                method: 'POST',
                body: JSON.stringify({ id: id, action: type })
            });
        },
        selfAction(type) {
            fetch(`https://${GetParentResourceName()}/selfAction`, {
                method: 'POST',
                body: JSON.stringify({ action: type })
            });
        },
        worldAction(type) {
            fetch(`https://${GetParentResourceName()}/adminAction`, {
                method: 'POST',
                body: JSON.stringify({ id: 0, action: type })
            });
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
    }
});

// Fechar com ESC
document.onkeyup = function (data) {
    if (data.which == 27) { // ESC Key
        app.closeMenu();
    }
};
