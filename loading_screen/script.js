// FiveM Loading Events
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.type === 'loadProgress') {
        var progress = Math.round(data.loadFraction * 100);
        document.getElementById('progress-bar').style.width = progress + '%';
        document.getElementById('progress-text').innerText = 'CARREGANDO: ' + progress + '%';
    }
});

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

// Forçar volume do vídeo se necessário ( FiveM browser pode bloquear som sem interação)
window.onload = function() {
    var video = document.getElementById('background-video');
    if (video) {
        video.volume = 0.5;
        // Tentativa de dar play se o autoplay falhar
        video.play().catch(function(error) {
            console.log("Autoplay bloqueado, aguardando carregamento.");
        });
    }
};
