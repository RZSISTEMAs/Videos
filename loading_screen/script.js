// FiveM Loading Events
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.type === 'loadProgress') {
        var progress = Math.round(data.loadFraction * 100);
        updateProgress(progress, 'CARREGANDO');
    }
});

var count = 0;
var thisCount = 0;
var lastEvent = "";

function updateProgress(percentage, text) {
    if (percentage > 100) percentage = 100;
    document.getElementById('progress-bar').style.width = percentage + '%';
    document.getElementById('progress-text').innerText = text + ': ' + percentage + '%';
}

const handlers = {
    startInitFunctionOrder(data) {
        count = data.count;
        thisCount = 0;
        lastEvent = "init";
    },
    initFunctionInvoked(data) {
        thisCount++;
        updateProgress(Math.round((thisCount / count) * 100), 'INICIALIZANDO');
    },
    startDataFileEntries(data) {
        count = data.count;
        thisCount = 0;
        lastEvent = "data";
    },
    performMapLoadFunction(data) {
        thisCount++;
        updateProgress(Math.round((thisCount / count) * 100), 'MAPA');
    }
};

window.addEventListener('message', function(event) {
    if (handlers[event.data.eventName]) {
        handlers[event.data.eventName](event.data);
    }
});

// Forçar reprodução do vídeo
window.addEventListener('DOMContentLoaded', (event) => {
    var video = document.getElementById('background-video');
    if (video) {
        video.muted = true; // Essencial para autoplay funcionar sempre
        video.play().catch(function(error) {
            console.log("Autoplay bloqueado pelo browser.");
        });
        
        // Se quiser som, tente desmutar após 2 segundos (alguns sistemas permitem após carregamento)
        setTimeout(() => {
            video.muted = false;
            video.volume = 0.5;
            console.log("Tentativa de liberar áudio...");
        }, 2000);
    }
});

