var colWidth;

function loadTracks() {
    if (!trackOverlay) {
        console.log('sorry, no trackOverlay obj fount');
        return;
    }

    $.each(trackOverlay.tracks, addTrack);
    // refresh html to load SVG
    $('#track-list,#problem-list').html(function () {
        return this.innerHTML;
    });
}

function addTrack(key, track) {
    var trackCol = $('<div class="col-md-2 col-sm-3" />');
    trackCol.append($('<strong />').text(key));
    trackCol.attr('id', key);
    trackCol.appendTo('#track-list');

    drawSvg(key, track);
}

function drawSvg(key, track) {
    drawSvgLib(key, track);
    drawSvgNative(key, track);

    switch (key) {
        case 'broken_track':
            $('#' + key).addClass('bg-danger').clone().prependTo('#problem-list');
            break;
        default:
            ;
    }
}

function drawSvgNative(key, track) {
    var trackSvg = $('<svg class="native" viewbox="0 0 420 324" />');
    $.each(track.paths, function (i, path) {
        $('<path stroke=green stroke-width=3 fill=none />').attr('d', path).appendTo(trackSvg);
    });
    trackSvg.appendTo($('#' + key));
}

function drawSvgLib(key, track) {
    var draw = new SVG(key).viewbox(0, 0, 420, 324).attr({class: 'lib'}); // .size(420,324);
    $.each(track.paths, function (i, path) {
        var track = draw.path(path).attr({
            fill: 'none',
            stroke: 'red',
            'stroke-width': 3
        });
        var startFinish = track.pointAt(0)
        draw.circle(10).attr({fill: 'red'}).move(startFinish.x, startFinish.y);
    });
}

$(function () {
    var waitCount = 0;

    var waitInterval = setInterval(function () {
        waitCount++;
        if (trackOverlay || waitCount > 10) {
            // console.log('trackOverlay found on attempt #', waitCount);
            loadTracks();
            clearInterval(waitInterval);
        }
    }, 1000);
});