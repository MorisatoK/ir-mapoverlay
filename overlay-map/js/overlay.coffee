window.app = angular.module 'app', [
    'ngAnimate'
    'ngSanitize'
]

app.service 'config', ($location) ->
    vars = $location.search()

    fps = parseInt(vars.fps) or 10
    fps = Math.max 1, Math.min 60, fps

    host: vars.host or 'localhost:8182'
    fps: fps

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
            updateCarClassIDs()
        if 'SessionInfo' in keys
            updatePositionsByCarIdx()
        if 'QualifyResultsInfo' in keys
            updateQualifyResultsByCarIdx()
        $rootScope.$apply()

    updateDriversByCarIdx = ->
        ir.data.myCarIdx = ir.data.DriverInfo.DriverCarIdx
        if not ir.data.DriversByCarIdx
            ir.data.DriversByCarIdx = {}
        for driver in ir.data.DriverInfo.Drivers
            ir.data.DriversByCarIdx[driver.CarIdx] = driver

    updateCarClassIDs = ->
        for driver in ir.data.DriverInfo.Drivers
            carClassId = driver.CarClassID
            if not ir.data.CarClassIDs
                ir.data.CarClassIDs = []
            if driver.UserID != -1 and driver.IsSpectator == 0 and carClassId not in ir.data.CarClassIDs
                ir.data.CarClassIDs.push carClassId

    updatePositionsByCarIdx = ->
        if not ir.data.PositionsByCarIdx
            ir.data.PositionsByCarIdx = []
        for session, i in ir.data.SessionInfo.Sessions
            while i >= ir.data.PositionsByCarIdx.length
                ir.data.PositionsByCarIdx.push {}
            if session.ResultsPositions
                for position in session.ResultsPositions
                    ir.data.PositionsByCarIdx[i][position.CarIdx] = position

    updateQualifyResultsByCarIdx = ->
        if not ir.data.QualifyResultsByCarIdx
            ir.data.QualifyResultsByCarIdx = {}
        for position in ir.data.QualifyResultsInfo.Results
            ir.data.QualifyResultsByCarIdx[position.CarIdx] = position

    return ir.data

##### Map

app.controller 'MapCtrl', ($scope, $element, iRData) ->
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

    throttle = Math.floor 1000/15
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
                trackMap = Raphael('map-overlay', trackOverlay.mapOptions.dimensions.width, trackOverlay.mapOptions.dimensions.height)

                for path, i in trackOverlay.tracksById[trackId].paths
                    if i == 0
                        trk_outline = trackMap.path(path).attr(trackOverlay.mapOptions.styles.track_outline).data('id', 'trk_outline')
                        track = trackMap.path(path).attr(trackOverlay.mapOptions.styles.track).data('id', 'track')

                        dims = Raphael.pathBBox(path)
                        trackMap.canvas.setAttribute('viewBox', '0 0 ' + (Math.round(dims.width) + 30) + ' ' + (Math.round(dims.height) + 30))
                        trackMap.canvas.setAttribute('preserveAspectRatio', trackOverlay.mapOptions.preserveAspectRatio)
                    else 
                        pit_outline = trackMap.path(path).attr(trackOverlay.mapOptions.styles.pits_outline).toBack().data('id', 'pit_outline')
                        pit = trackMap.path(path).attr(trackOverlay.mapOptions.styles.pits).data('id', 'pit')
                
                trackLength = track.getTotalLength()
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
                        drivers[driver].attr(trackOverlay.mapOptions.styles.driver.default)

                    if typeof drivers[camCarIdx] != 'undefined'
                        drivers[camCarIdx].attr(trackOverlay.mapOptions.styles.driver.camera).toFront()
                        driverCarNum[camCarIdx].toFront()

                watchPitRoad = $scope.$watch 'ir.CarIdxOnPitRoad', (n, o) ->
                    if not n or not o
                        return

                    if arrayEqual(n, o)
                        return

                    carIdxOnPitRoad = n

                    for pitStatus, carIdx in carIdxOnPitRoad when carIdx >= skipCars
                        if pitStatus
                            drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.pit)
                        else if typeof drivers[carIdx] != 'undefined'
                            drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.onTrack)
                , true

                watchOfftracks = $scope.$watch 'ir.CarIdxTrackSurface', (n, o) ->
                    if not n or not o
                        return

                    if arrayEqual(n, o)
                        return

                    for trackSurface, carIdx in n when carIdx >= skipCars
                        if trackSurface == 0 and o[carIdx] != 0
                            drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.offTrack)
                        else if trackSurface != 0 and o[carIdx] == 0
                            drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.default)

                            if carIdx == ir.CamCarIdx
                                drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.camera)
                , true

                watchPositions = $scope.$watch 'ir.PositionsByCarIdx', (n, o) ->
                    if not n
                        return

                    positionsByCarIdx = n

                    for carIdx, driver of positionsByCarIdx[ir.SessionNum]
                        if typeof driverCarNum[carIdx] != 'undefined'
                            driverCarNum[carIdx].attr(text: driver.ClassPosition + 1).attr(trackOverlay.mapOptions.styles.driver.posNum)
                , true

                watchSessionNum = $scope.$watch 'ir.SessionNum', (n, o) ->
                    if not n? or not ir.DriversByCarIdx
                        return

                    if ir.WeekendInfo.SimMode == 'replay'
                        return

                    for idx, text of driverCarNum
                        text.attr(text: ir.DriversByCarIdx[idx].CarNumber).attr(trackOverlay.mapOptions.styles.driver.carNum)
                    

    arrayEqual = (a, b) ->
        a.length is b.length and a.every (elem, i) -> elem is b[i]

    drawStartFinishLine = (refPoint) ->
        startCoords = track.getPointAtLength(refPoint * trackLength)
        pathAngle = track.getPointAtLength((refPoint * trackLength) + 0.1)
        rotateAngle = Raphael.angle(startCoords.x, startCoords.y, pathAngle.x, pathAngle.y)
        startFinishLine = trackMap.path(getLinePath(startCoords.x, startCoords.y - 15, startCoords.x, startCoords.y + 15)).transform('r' + rotateAngle).attr(trackOverlay.mapOptions.styles.startFinish)

    getLinePath = (startX, startY, endX, endY) ->
        'M' + startX + ' ' + startY + ' L' + endX + ' ' + endY

    updateMap = () ->
        if ir.SessionInfo.Sessions[ir.SessionNum].SessionType == 'Race'
            skipCars = 1

        for carIdxDist, carIdx in CarIdxLapDistPct when carIdx >= skipCars
            if typeof drivers[carIdx] == 'undefined'
                if carIdxDist != -1
                    driverCoords = track.getPointAtLength(trackLength*carIdxDist)

                    carClassId = ir.DriversByCarIdx[carIdx].CarClassID
                    if ir.CarClassIDs and ir.CarClassIDs.length > 1 and carClassId > 0
                        carClassIndex = ir.CarClassIDs.indexOf(carClassId) % 3
                    else carClassIndex = 1

                    drivers[carIdx] = trackMap.circle(driverCoords.x, driverCoords.y, trackOverlay.mapOptions.styles.driver.circleRadius).attr(trackOverlay.mapOptions.styles.driver.default).attr(fill: trackOverlay.mapOptions.styles.driver.class[carClassIndex])

                    driverCarNum[carIdx] = trackMap.text(driverCoords.x, driverCoords.y, '').attr(trackOverlay.mapOptions.styles.driver.circleNum)

                    if typeof ir.PositionsByCarIdx[ir.SessionNum][carIdx] != 'undefined'
                        driverCarNum[carIdx].attr(text: ir.PositionsByCarIdx[ir.SessionNum][carIdx].ClassPosition + 1).attr(trackOverlay.mapOptions.styles.driver.posNum)
                    else
                        driverCarNum[carIdx].attr(text: ir.DriversByCarIdx[carIdx].CarNumber).attr(trackOverlay.mapOptions.styles.driver.carNum)

                    if carIdx == ir.myCarIdx
                        drivers[carIdx].attr(fill: shadeColor(trackOverlay.mapOptions.styles.driver.class[carClassIndex], -0.3))
                        driverCarNum[carIdx].node.setAttribute('id', 'player')

                    if carIdx == ir.CamCarIdx
                        drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.camera).toFront()
                        driverCarNum[carIdx].toFront()

                    if ir.CarIdxOnPitRoad[carIdx]
                        drivers[carIdx].attr(trackOverlay.mapOptions.styles.driver.pit)

            else
                if carIdxDist == -1
                    drivers[carIdx].hide()
                    driverCarNum[carIdx].hide()
                else
                    driverCoords = track.getPointAtLength(trackLength*carIdxDist)
                    drivers[carIdx].attr(cx: driverCoords.x, cy: driverCoords.y)
                    driverCarNum[carIdx].attr(x: driverCoords.x, y: driverCoords.y)

                    if carIdx == ir.CamCarIdx and driverCarNum[carIdx].next != null
                        drivers[carIdx].toFront()
                        driverCarNum[carIdx].toFront()

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

