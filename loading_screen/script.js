var player;
function onYouTubeIframeAPIReady() {
    player = new YT.Player('youtube-player', {
        height: '100%',
        width: '100%',
        videoId: 'lVhJ_A8XUgc',
        playerVars: {
            'autoplay': 1,
            'controls': 0,
            'showinfo': 0,
            'rel': 0,
            'loop': 1,
            'playlist': 'lVhJ_A8XUgc', // Necessário para looping
            'mute': 0 // Se quiser música, deixe mudo como 0, mas atente para políticas de autoplay do browser
        },
        events: {
            'onReady': onPlayerReady
        }
    });
}

function onPlayerReady(event) {
    event.target.playVideo();
    event.target.setVolume(50); // Volume em 50%
}

// FiveM Loading Events
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.type === 'loadProgress') {
        var progress = Math.round(data.loadFraction * 100);
        document.getElementById('progress-bar').style.width = progress + '%';
        document.getElementById('progress-text').innerText = 'CARREGANDO: ' + progress + '%';
    }
});

// Outro evento comum para log de linhas, caso precise
var count = 0;
var thisCount = 0;

const handlers = {
    startInitFunctionOrder(data) {
        count = data.count;
    },
    initFunctionInvoked(data) {
        thisCount++;
        var progress = Math.round((thisCount / count) * 100);
        document.getElementById('progress-bar').style.width = progress + '%';
        document.getElementById('progress-text').innerText = 'INICIALIZANDO: ' + progress + '%';
    },
    startDataFileEntries(data) {
        count = data.count;
    },
    performMapLoadFunction(data) {
        thisCount++;
        var progress = Math.round((thisCount / count) * 100);
        document.getElementById('progress-bar').style.width = progress + '%';
        document.getElementById('progress-text').innerText = 'MAPA: ' + progress + '%';
    }
};

window.addEventListener('message', function(event) {
    if (handlers[event.data.eventName]) {
        handlers[event.data.eventName](event.data);
    }
});
