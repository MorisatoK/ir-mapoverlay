window.app = angular.module 'overlay-map', [
    'ngAnimate'
    'ngSanitize'
]

app.service 'config', ($location) ->
    vars = $location.search()

    fps = parseInt(vars.fps) or 15
    fps = Math.max 1, Math.min 60, fps

    baseStrokeWidth = parseInt(vars.trackWidth) or 10
    baseStrokeWidth = Math.max 1, Math.min 30, baseStrokeWidth

    driverCircle = parseInt(vars.driverCircle) or 12
    driverCircle = Math.max 1, Math.min 30, driverCircle

    driverHighlightWidth = parseInt(vars.driverHighlightWidth) or 4
    driverHighlightWidth = Math.max 3, Math.min 10, driverHighlightWidth

    host: vars.host or 'localhost:8182'
    fps: fps

    mapOptions:
        dimensions:
            width: 420
            height: 324
        preserveAspectRatio: 'xMidYMax meet'
        styles:
            track:
                fill: 'none'
                stroke: vars.trackColor or '#000000'
                'stroke-width': baseStrokeWidth.toString()
                'stroke-miterlimit': baseStrokeWidth.toString()
                'stroke-opacity': '1'
            pits:
                fill: 'none'
                stroke: vars.trackColor or '#000000'
                'stroke-width': (baseStrokeWidth * 0.7).toString()
                'stroke-miterlimit': (baseStrokeWidth * 0.7).toString()
                'stroke-opacity': '1'
            track_outline:
                fill: 'none'
                stroke: vars.trackOutlineColor or '#FFFFFF'
                'stroke-width': (baseStrokeWidth * 1.8).toString()
                'stroke-miterlimit': (baseStrokeWidth * 1.8).toString()
                'stroke-opacity': '0.3'
            pits_outline:
                fill: 'none'
                stroke: vars.trackOutlineColor or '#FFFFFF'
                'stroke-width': (baseStrokeWidth * 1.5).toString()
                'stroke-miterlimit': (baseStrokeWidth * 1.5).toString()
                'stroke-opacity': '0.3'
            startFinish:
                stroke: vars.startFinishColor or '#FF0000'
                'stroke-width': (baseStrokeWidth * 0.5).toString()
                'stroke-miterlimit': (baseStrokeWidth).toString()
                'stroke-opacity': '1'
            driver:
                circleRadius: driverCircle
                default:
                    'stroke-width': '0'
                    stroke: vars.driverHighlightCam or '#4DFF51'
                camera:
                    'stroke-width': driverHighlightWidth.toString()
                pit:
                    opacity: '0.5'
                onTrack:
                    opacity: '1'
                offTrack:
                    'stroke-width': driverHighlightWidth.toString()
                    stroke: vars.driverHighlightOfftrack or '#FF0000'
                circleNum:
                    font: ''
                posNum:
                    fill: vars.driverPosNum or '#000000'
                    opacity: '1'
                carNum:
                    fill: vars.driverCarNum or '#666666'
                    opacity: '0.75'

    requestParams: [
        # yaml
        'DriverInfo'
        'SessionInfo'

        # telemetry
        'CamCarIdx'
        'CarIdxLapDistPct'
        'CarIdxOnPitRoad'
        'CarIdxTrackSurface'
        'IsReplayPlaying'
        'ReplayFrameNumEnd'
        'SessionNum'
    ]
    requestParamsOnce: [
        # yaml
        'QualifyResultsInfo'
        'WeekendInfo'
    ]

app.service 'iRData', ($rootScope, config) ->
    ir = new IRacing \
        config.requestParams,
        config.requestParamsOnce,
        config.fps,
        config.host

    ir.onConnect = ->
        ir.data.connected = true
        $rootScope.$apply()

    ir.onDisconnect = ->
        ir.data.connected = false
        $rootScope.$apply()

    ir.onUpdate = (keys) ->
        if 'DriverInfo' in keys
            updateDriversByCarIdx()
        if 'SessionInfo' in keys
            updatePositionsByCarIdx()
        if 'QualifyResultsInfo' in keys
            updateQualifyResultsByCarIdx()
        $rootScope.$apply()

    updateDriversByCarIdx = ->
        ir.data.myCarIdx = ir.data.DriverInfo.DriverCarIdx
        ir.data.DriversByCarIdx ?= {}
        for driver in ir.data.DriverInfo.Drivers
            ir.data.DriversByCarIdx[driver.CarIdx] = driver

    updatePositionsByCarIdx = ->
        ir.data.PositionsByCarIdx ?= []
        for session, i in ir.data.SessionInfo.Sessions
            while i >= ir.data.PositionsByCarIdx.length
                ir.data.PositionsByCarIdx.push {}
            if session.ResultsPositions
                for position in session.ResultsPositions
                    ir.data.PositionsByCarIdx[i][position.CarIdx] = position

    updateQualifyResultsByCarIdx = ->
        ir.data.QualifyResultsByCarIdx ?= {}
        for position in ir.data.QualifyResultsInfo.Results
            ir.data.QualifyResultsByCarIdx[position.CarIdx] = position

    return ir.data

##### Map

app.controller 'MapCtrl', ($scope, $element, iRData, config) ->
    ir = $scope.ir = iRData

    CarIdxLapDistPct = null
    currentRun = null
    prevRun = null
    trackMap = null
    track = null
    trackLength = null
    drawMap = null
    watchCamCar = null
    watchPitRoad = null
    watchPositions = null
    camCarIdx = null
    carIdxOnPitRoad = null
    positionsByCarIdx = null

    drivers = {}
    driverCarNum = {}

    throttle = Math.floor 1000/config.fps
    skipCars = 0

    # hide if not live, but loaded replay is ok
    replayFrameWatcher = null
    checkTrackOverlayHide = ->
        if not ir.WeekendInfo or ir.WeekendInfo.SimMode == 'replay'
            return

        if ir.IsReplayPlaying
            if not replayFrameWatcher?
                replayFrameWatcher = $scope.$watch 'ir.ReplayFrameNumEnd', checkTrackOverlayHide
        else if replayFrameWatcher?
            replayFrameWatcher()
            replayFrameWatcher = null
        $element.toggleClass 'ng-hide', \
            (ir.IsReplayPlaying and ir.ReplayFrameNumEnd > 10)


    $scope.$watch 'ir.IsReplayPlaying', checkTrackOverlayHide

    $scope.$watch 'ir.connected', (n, o) ->
        $element.toggleClass 'ng-hide', not n
        if n == false
            if trackMap != null
                trackMap.remove()
                trackMap = null
                track = null
                trackLength= null
                camCarIdx = null
                carIdxOnPitRoad = null
                positionsByCarIdx = null
                skipCars = 0
                drivers = {}
                driverCarNum = {}
                if drawMap?
                    drawMap()
                    drawMap = null
                if watchCamCar?
                    watchCamCar()
                    watchCamCar = null
                if watchPitRoad?
                    watchPitRoad()
                    watchPitRoad = null
                if watchOfftracks?
                    watchOfftracks()
                    watchOfftracks = null
                if watchPositions?
                    watchPositions()
                    watchPositions = null
                if watchSessionNum?
                    watchSessionNum()
                    watchSessionNum = null

    $scope.$watch 'ir.WeekendInfo', (n, o) ->
        if typeof ir.WeekendInfo != 'undefined'
            trackId = ir.WeekendInfo.TrackID

            if typeof trackOverlay.tracksById[trackId] != 'undefined'
                trackMap = SVG('map-overlay').size(config.mapOptions.dimensions.width, config.mapOptions.dimensions.height)

                for path, i in trackOverlay.tracksById[trackId].paths
                    if i == 0
                        trk_outline = trackMap.path(path).attr(config.mapOptions.styles.track_outline).data('id', 'trk_outline')
                        track = trackMap.path(path).attr(config.mapOptions.styles.track).data('id', 'track')

                        dims = track.bbox()
                        trackMap.attr('viewBox', '0 0 ' + (Math.round(dims.width) + 30) + ' ' + (Math.round(dims.height) + 30))
                        trackMap.attr('preserveAspectRatio', config.mapOptions.preserveAspectRatio)
                    else 
                        pit_outline = trackMap.path(path).attr(config.mapOptions.styles.pits_outline).back().data('id', 'pit_outline')
                        pit = trackMap.path(path).attr(config.mapOptions.styles.pits).data('id', 'pit')
                
                trackLength = track.length()
                drawStartFinishLine(trackOverlay.tracksById[trackId].extendedLine || 0)

                drawMap = $scope.$watch 'ir.CarIdxLapDistPct', (n, o) ->
                    if not n
                        return
                    
                    CarIdxLapDistPct = n

                    currentRun = new Date().getTime()
                    if currentRun >= (prevRun + throttle)
                        prevRun = currentRun
                        updateMap()

                watchCamCar = $scope.$watch 'ir.CamCarIdx', (n, o) ->
                    if not n?
                        return

                    camCarIdx = n

                    for driver, circle of drivers
                        drivers[driver].attr(config.mapOptions.styles.driver.default)

                    if typeof drivers[camCarIdx] != 'undefined'
                        drivers[camCarIdx].attr(config.mapOptions.styles.driver.camera).front()
                        driverCarNum[camCarIdx].front()

                watchPitRoad = $scope.$watch 'ir.CarIdxOnPitRoad', (n, o) ->
                    if not n or not o
                        return

                    if arrayEqual(n, o)
                        return

                    carIdxOnPitRoad = n

                    for pitStatus, carIdx in carIdxOnPitRoad when carIdx >= skipCars
                        if pitStatus
                            drivers[carIdx].attr(config.mapOptions.styles.driver.pit)
                        else if typeof drivers[carIdx] != 'undefined'
                            drivers[carIdx].attr(config.mapOptions.styles.driver.onTrack)
                , true

                watchOfftracks = $scope.$watch 'ir.CarIdxTrackSurface', (n, o) ->
                    if not n or not o
                        return

                    if arrayEqual(n, o)
                        return

                    for trackSurface, carIdx in n when carIdx >= skipCars
                        if trackSurface == 0 and o[carIdx] != 0
                            drivers[carIdx].attr(config.mapOptions.styles.driver.offTrack)
                        else if trackSurface != 0 and o[carIdx] == 0
                            drivers[carIdx].attr(config.mapOptions.styles.driver.default)

                            if carIdx == ir.CamCarIdx
                                drivers[carIdx].attr(config.mapOptions.styles.driver.camera)
                , true

                watchPositions = $scope.$watch 'ir.PositionsByCarIdx', (n, o) ->
                    if not n
                        return

                    positionsByCarIdx = n

                    for carIdx, driver of positionsByCarIdx[ir.SessionNum]
                        if typeof driverCarNum[carIdx] != 'undefined'
                            driverPosition = if driver.ClassPosition == -1 then driver.Position else driver.ClassPosition + 1
                            driverCarNum[carIdx].plain(driverPosition).attr(config.mapOptions.styles.driver.posNum)
                , true

                watchSessionNum = $scope.$watch 'ir.SessionNum', (n, o) ->
                    if not n? or not ir.DriversByCarIdx
                        return

                    if ir.WeekendInfo.SimMode == 'replay'
                        return

                    for idx, text of driverCarNum
                        text.plain(ir.DriversByCarIdx[idx].CarNumber).attr(config.mapOptions.styles.driver.carNum)
                    

    arrayEqual = (a, b) ->
        a.length is b.length and a.every (elem, i) -> elem is b[i]

    drawStartFinishLine = (refPoint) ->
        startCoords = track.pointAt(refPoint * trackLength)
        pathAngle = track.pointAt((refPoint * trackLength) + 0.1)
        rotateAngle = getLineAngle(startCoords.x, startCoords.y, pathAngle.x, pathAngle.y)
        startFinishLine = trackMap.path(getLinePath(startCoords.x, startCoords.y - 15, startCoords.x, startCoords.y + 15)).rotate(rotateAngle).attr(config.mapOptions.styles.startFinish)

    getLinePath = (startX, startY, endX, endY) ->
        'M' + startX + ' ' + startY + ' L' + endX + ' ' + endY

    getLineAngle = (x1, y1, x2, y2) ->
        x = x1 - x2
        y = y1 - y2

        if (!x && !y)
            return 0

        return (180 + Math.atan2(-y, -x) * 180 / Math.PI + 360) % 360

    updateMap = () ->
        if not ir.SessionInfo.Sessions[ir.SessionNum]
            return

        if ir.SessionInfo.Sessions[ir.SessionNum].SessionType == 'Race'
            skipCars = 1

        for carIdxDist, carIdx in CarIdxLapDistPct when carIdx >= skipCars
            if typeof drivers[carIdx] == 'undefined'
                if carIdxDist != -1
                    driverCoords = track.pointAt(trackLength*carIdxDist)

                    carClassColor = ir.DriversByCarIdx[carIdx].CarClassColor
                    if carClassColor == 0
                        carClassId = ir.DriversByCarIdx[carIdx].CarClassID
                        for d in ir.DriverInfo.Drivers
                            if d.CarClassID == carClassId and d.CarClassColor
                                carClassColor = d.CarClassColor
                    if carClassColor == 0xffffff
                        carClassColor = 0xffda59
                    carClassColor = '#' + carClassColor.toString(16)

                    drivers[carIdx] = trackMap.circle(config.mapOptions.styles.driver.circleRadius * 2).fill(carClassColor).cx(driverCoords.x).cy(driverCoords.y).attr(config.mapOptions.styles.driver.default).attr(fill: carClassColor)

                    driverCarNum[carIdx] = trackMap.plain('').cx(driverCoords.x).cy(driverCoords.y).attr(config.mapOptions.styles.driver.circleNum)

                    if typeof ir.PositionsByCarIdx[ir.SessionNum][carIdx] != 'undefined'
                        driverPosition = if ir.PositionsByCarIdx[ir.SessionNum][carIdx].ClassPosition == -1 then ir.PositionsByCarIdx[ir.SessionNum][carIdx].Position else ir.PositionsByCarIdx[ir.SessionNum][carIdx].ClassPosition + 1
                        driverCarNum[carIdx].plain(driverPosition).attr(config.mapOptions.styles.driver.posNum)
                    else
                        driverCarNum[carIdx].plain(ir.DriversByCarIdx[carIdx].CarNumber).attr(config.mapOptions.styles.driver.carNum)

                    if carIdx == ir.myCarIdx
                        drivers[carIdx].fill(shadeColor(carClassColor, -0.3))
                        driverCarNum[carIdx].attr('id', 'player')

                    if carIdx == ir.CamCarIdx
                        drivers[carIdx].attr(config.mapOptions.styles.driver.camera).front()
                        driverCarNum[carIdx].front()

                    if ir.CarIdxOnPitRoad[carIdx]
                        drivers[carIdx].attr(config.mapOptions.styles.driver.pit)

            else
                if carIdxDist == -1
                    drivers[carIdx].hide()
                    driverCarNum[carIdx].hide()
                else
                    driverCoords = track.pointAt(trackLength*carIdxDist)
                    drivers[carIdx].cx(driverCoords.x).cy(driverCoords.y)
                    driverCarNum[carIdx].cx(driverCoords.x).cy(driverCoords.y)

                    if carIdx == ir.CamCarIdx and driverCarNum[carIdx].next != null
                        drivers[carIdx].front()
                        driverCarNum[carIdx].front()

                    driverCarNum[carIdx].show()
                    drivers[carIdx].show()

shadeColor = (color, percent) ->
    f = parseInt(color.slice(1), 16)
    t = (if percent < 0 then 0 else 255)
    p = (if percent < 0 then percent * -1 else percent)
    R = f >> 16
    G = f >> 8 & 0x00FF
    B = f & 0x0000FF
    '#' + (0x1000000 + (Math.round((t - R) * p) + R) * 0x10000 + (Math.round((t - G) * p) + G) * 0x100 + (Math.round((t - B) * p) + B)).toString(16).slice(1)

##### /Map

angular.bootstrap document, [app.name]

