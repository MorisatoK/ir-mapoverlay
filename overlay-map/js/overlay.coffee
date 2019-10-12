window.app = angular.module 'overlay-map', [
    'ngAnimate'
    'ngSanitize'
]

app.config ($locationProvider) ->
    $locationProvider.hashPrefix ''

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

    driverGroups = vars.dGrp
    driverGroupsColors = vars.dGrpClr

    if (driverGroups and driverGroupsColors)
        if driverGroups instanceof Array
            for group, i in driverGroups
                driverGroups[i] = group.split(',')

                for item, j in driverGroups[i]
                    driverGroups[i][j] = parseInt(item)
        else
            driverGroups = driverGroups.split(',')
            driverGroups = new Array(driverGroups)

            for item, i in driverGroups[0]
                driverGroups[0][i] = parseInt(item)

            driverGroupsColors = new Array(driverGroupsColors)

        if driverGroups.length == driverGroupsColors.length
            driverGroupsEnabled = true
        else
            driverGroupsEnabled = false

    else
        driverGroupsEnabled = false

    driverGroupsEnabled: driverGroupsEnabled
    driverGroups: driverGroups
    driverGroupsColors: driverGroupsColors

    showSectors: vars.showSectors == 'true'

    host: vars.host or 'localhost:8182'
    fps: fps

    mapOptions:
        preserveAspectRatio: getPreserveAspectRatio vars.trackAlignment ? 'center'
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
            sectors:
                stroke: vars.sectorColor or '#FFDA59'
                'stroke-width': (baseStrokeWidth * 0.3).toString()
                'stroke-miterlimit': (baseStrokeWidth).toString()
                'stroke-opacity': '1'
            driver:
                circleRadius: driverCircle
                circleColor: vars.circleColor or false
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
                    fill: vars.driverPosNum or '#000000'
                posNum:
                    opacity: '1'
                carNum:
                    opacity: '0.5'
                highlightNum:
                    fill: vars.highlightNum or '#FFFFFF'
                playerHighlight: vars.playerHighlight or false

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
        'SplitTimeInfo'
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

    updateCarClassIDs = ->
        for driver in ir.data.DriverInfo.Drivers
            carClassId = driver.CarClassID
            ir.data.CarClassIDs ?= []
            if driver.UserID != -1 and driver.IsSpectator == 0 and carClassId not in ir.data.CarClassIDs
                ir.data.CarClassIDs.push carClassId

    return ir.data

app.controller 'MapCtrl', ($scope, $element, iRData, config) ->
    ir = $scope.ir = iRData

    replayFrameWatcher = null

    mapVars =
        skipCars: 0
        trackMap: null
        track: null
        extendedTrack: null
        extendedTrackMaxDist: null
        trackLength: null
        extenededTrackLength: null
        drivers: {}

    $scope.$watch 'ir.IsReplayPlaying', checkTrackOverlayHide

    $scope.$watch 'ir.connected', (n, o) ->
        $element.toggleClass 'ng-hide', not n
        if not n and !!mapVars.trackMap
            mapVars.trackMap.remove()
            mapVars.trackMap = null
            mapVars.track = null
            mapVars.extendedTrack = null
            mapVars.extendedTrackMaxDist = null
            mapVars.trackLength = null
            mapVars.extenededTrackLength = null
            mapVars.skipCars = 0
            mapVars.drivers = {}

    $scope.$watch 'ir.WeekendInfo', ->
        if not ir.WeekendInfo
            return

        trackId = ir.WeekendInfo.TrackID

        setTimeout ( ->
            initMap(trackId)
        ), 1000

        $scope.$watch 'ir.CarIdxLapDistPct', drawMap
        $scope.$watch 'ir.CamCarIdx', watchCamCar
        $scope.$watch 'ir.CarIdxOnPitRoad', watchPitRoad
        $scope.$watch 'ir.CarIdxTrackSurface', watchOfftracks
        $scope.$watch 'ir.PositionsByCarIdx', watchPositions, true
        $scope.$watch 'ir.SessionNum', watchSessionNum

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

    initMap = (trackId) ->
        if not trackOverlay.tracksById[trackId]
            return

        mapVars.trackMap = SVG('map-overlay')

        for path, i in trackOverlay.tracksById[trackId].paths
            if i == 0
                trk_outline = mapVars.trackMap.path(path).attr(config.mapOptions.styles.track_outline).data('id', 'trk_outline')
                mapVars.track = mapVars.trackMap.path(path).attr(config.mapOptions.styles.track).data('id', 'track')

                dims = mapVars.track.bbox()
                mapWidth = Math.round(dims.width + 40)
                mapHeight = Math.round(dims.height + 40)

                mapVars.trackMap.attr('viewBox', "0 0 #{mapWidth} #{mapHeight}")
                mapVars.trackMap.attr('preserveAspectRatio', config.mapOptions.preserveAspectRatio)
            else
                pit_outline = mapVars.trackMap.path(path).attr(config.mapOptions.styles.pits_outline).back().data('id', 'pit_outline')
                pit = mapVars.trackMap.path(path).attr(config.mapOptions.styles.pits).data('id', 'pit')

        if trackOverlay.tracksById[trackId].extendedTrack
            ext_trk_outline = mapVars.trackMap.path(trackOverlay.tracksById[trackId].extendedTrack[1]).attr(config.mapOptions.styles.track_outline).data('id', 'ext_trk_outline')
            mapVars.extendedTrack = mapVars.trackMap.path(trackOverlay.tracksById[trackId].extendedTrack[1]).attr(config.mapOptions.styles.track).data('id', 'ext_track')
            mapVars.extendedTrackLength = mapVars.extendedTrack.length()
            mapVars.extendedTrackMaxDist = trackOverlay.tracksById[trackId].extendedTrack[0]

        mapVars.trackLength = mapVars.track.length()

        if trackOverlay.tracksById[trackId].extendedLine
            for extendedLine in trackOverlay.tracksById[trackId].extendedLine
                drawStartFinishLine(extendedLine)
        else
            drawStartFinishLine(0)

        if config.showSectors
            drawSectors()

    drawMap = ->
        requestAnimationFrame(updateMap)

    watchCamCar = ->
        for index, driver of mapVars.drivers
            driver.get(0).attr(config.mapOptions.styles.driver.default)

        if !!mapVars.drivers[ir.CamCarIdx]
            mapVars.drivers[ir.CamCarIdx].get(0).attr(config.mapOptions.styles.driver.camera)

    watchPitRoad = ->
        if not ir.CarIdxOnPitRoad
            return

        for pitStatus, carIdx in ir.CarIdxOnPitRoad when carIdx >= mapVars.skipCars
            if not mapVars.drivers[carIdx]
                continue

            if pitStatus
                mapVars.drivers[carIdx].attr(config.mapOptions.styles.driver.pit)
            else if !!mapVars.drivers[carIdx]
                mapVars.drivers[carIdx].attr(config.mapOptions.styles.driver.onTrack)

    watchOfftracks = (n, o) ->
        if not n or not o
            return

        for trackSurface, carIdx in n when carIdx >= mapVars.skipCars
            if not mapVars.drivers[carIdx]
                continue

            if trackSurface == 0 and o[carIdx] != 0
                mapVars.drivers[carIdx].get(0).attr(config.mapOptions.styles.driver.offTrack)
            else if trackSurface != 0 and o[carIdx] == 0
                mapVars.drivers[carIdx].get(0).attr(config.mapOptions.styles.driver.default)

                if carIdx == ir.CamCarIdx
                    mapVars.drivers[carIdx].get(0).attr(config.mapOptions.styles.driver.camera)

    watchPositions = ->
        if not ir.PositionsByCarIdx
            return

        for carIdx, driver of ir.PositionsByCarIdx[ir.SessionNum]
            if !!mapVars.drivers[carIdx]
                driverPosition = if driver.ClassPosition == -1 then driver.Position else driver.ClassPosition + 1
                mapVars.drivers[carIdx].get(1).plain(driverPosition).attr(config.mapOptions.styles.driver.posNum).center(0, 0)

    watchSessionNum = (n, o) ->
        if not n? or not ir.DriversByCarIdx
            return

        if ir.WeekendInfo.SimMode == 'replay'
            return

        for index, driver of mapVars.drivers
            driver.get(1).plain(ir.DriversByCarIdx[index].CarNumber).attr(config.mapOptions.styles.driver.carNum)

    showClassBubble = (carIdx) ->
        if not ir.CarClassIDs or ir.CarClassIDs.length <= 1
            return

        classBubble = mapVars.drivers[carIdx].get(2)

        if !!classBubble and !classBubble.visible()
            classBubble.show()

    updateMap = ->
        if not ir.SessionInfo or not ir.SessionInfo.Sessions[ir.SessionNum]
            return

        if ir.SessionInfo.Sessions[ir.SessionNum].SessionType == 'Race'
            mapVars.skipCars = 1

        for carIdxDist, carIdx in ir.CarIdxLapDistPct when carIdx >= mapVars.skipCars
            if not mapVars.drivers[carIdx]
                if carIdxDist == -1
                    continue

                driverCoords = getDriverCoords carIdxDist
                carClassColor = getCarClassColor carIdx

                circleColor = carClassColor
                numberColor = config.mapOptions.styles.driver.circleNum

                if config.mapOptions.styles.driver.circleColor
                    circleColor = config.mapOptions.styles.driver.circleColor
                    drawClassBubble = true

                if config.driverGroupsEnabled
                    for group, i in config.driverGroups
                        if (ir.DriversByCarIdx[carIdx].UserID in group) or (ir.WeekendInfo.TeamRacing and ir.DriversByCarIdx[carIdx].TeamID in group)
                            circleColor = config.driverGroupsColors[i]
                            numberColor = config.mapOptions.styles.driver.highlightNum
                            drawClassBubble = true
                            break

                driverNumber = mapVars.trackMap.plain('').attr(numberColor)
                driverCircle = mapVars.trackMap.circle(config.mapOptions.styles.driver.circleRadius * 2).attr(config.mapOptions.styles.driver.default).fill(circleColor)

                if not ir.PositionsByCarIdx[ir.SessionNum][carIdx]
                    driverNumber.plain(ir.DriversByCarIdx[carIdx].CarNumber).attr(config.mapOptions.styles.driver.carNum)
                else
                    driverPosition = if ir.PositionsByCarIdx[ir.SessionNum][carIdx].ClassPosition == -1 then ir.PositionsByCarIdx[ir.SessionNum][carIdx].Position else ir.PositionsByCarIdx[ir.SessionNum][carIdx].ClassPosition + 1
                    driverNumber.plain(driverPosition).attr(config.mapOptions.styles.driver.posNum)

                if carIdx == ir.myCarIdx
                    driverNumber.attr(config.mapOptions.styles.driver.highlightNum)

                    if config.mapOptions.styles.driver.playerHighlight
                        driverCircle.fill(config.mapOptions.styles.driver.playerHighlight)
                    else
                        driverCircle.fill(shadeColor(circleColor, -0.3))

                driverCircle.center(0, 0)
                driverNumber.center(0, 0)

                driver = mapVars.trackMap.group()
                driver.add(driverCircle)
                driver.add(driverNumber)

                if drawClassBubble
                    classBubble = mapVars.trackMap.circle(config.mapOptions.styles.driver.circleRadius).fill(carClassColor).center(config.mapOptions.styles.driver.circleRadius * .85, -config.mapOptions.styles.driver.circleRadius * .85).hide()
                    driver.add(classBubble)
                    drawClassBubble = false

                driver.move(driverCoords.x, driverCoords.y)

                mapVars.drivers[carIdx] = driver

                if carIdx == ir.CamCarIdx
                    mapVars.drivers[carIdx].get(0).attr(config.mapOptions.styles.driver.camera)

                if ir.CarIdxOnPitRoad[carIdx]
                    mapVars.drivers[carIdx].attr(config.mapOptions.styles.driver.pit)
            else
                if carIdxDist == -1
                    mapVars.drivers[carIdx].hide()
                else
                    driverCoords = getDriverCoords carIdxDist
                    mapVars.drivers[carIdx].move(driverCoords.x, driverCoords.y)

                    if carIdx == ir.CamCarIdx and !!mapVars.drivers[carIdx].next()
                        mapVars.drivers[carIdx].front()

                    mapVars.drivers[carIdx].show()
                    showClassBubble(carIdx)


    getDriverCoords = (carIdxDist) ->
        if mapVars.extendedTrack && carIdxDist >= 1
            driverCoords = mapVars.extendedTrack.pointAt(mapVars.extendedTrackLength*((carIdxDist - 1) / (mapVars.extendedTrackMaxDist - 1)))
        else
            driverCoords = mapVars.track.pointAt(mapVars.trackLength*carIdxDist)

        return driverCoords

    drawStartFinishLine = (refPoint) ->
        startCoords = mapVars.track.pointAt(refPoint * mapVars.trackLength)
        pathAngle = mapVars.track.pointAt((refPoint * mapVars.trackLength) + 0.1)
        rotateAngle = getLineAngle(startCoords.x, startCoords.y, pathAngle.x, pathAngle.y)
        startFinishLine = mapVars.trackMap.path(getLinePath(startCoords.x, startCoords.y - 15, startCoords.x, startCoords.y + 15)).rotate(rotateAngle).attr(config.mapOptions.styles.startFinish)

    drawSectors = () ->
        if not ir.SplitTimeInfo
            return

        for sector, i in ir.SplitTimeInfo.Sectors when i >= 1
            sectorCoords = mapVars.track.pointAt(sector.SectorStartPct * mapVars.trackLength)
            sectorAngle = mapVars.track.pointAt((sector.SectorStartPct * mapVars.trackLength) + 0.1)
            sectorRotation = getLineAngle(sectorCoords.x, sectorCoords.y, sectorAngle.x, sectorAngle.y)
            sectorLine = mapVars.trackMap.path(getLinePath(sectorCoords.x, sectorCoords.y - 10, sectorCoords.x, sectorCoords.y + 10)).rotate(sectorRotation).attr(config.mapOptions.styles.sectors)

    getCarClassColor = (carIdx) ->
        carClassColor = ir.DriversByCarIdx[carIdx].CarClassColor

        if carClassColor == 0
            carClassId = ir.DriversByCarIdx[carIdx].CarClassID
            for d in ir.DriverInfo.Drivers
                if d.CarClassID == carClassId and d.CarClassColor
                    carClassColor = d.CarClassColor
        if carClassColor == 0xffffff
            carClassColor = 0xffda59

        return carClassColor = '#' + carClassColor.toString(16)

shadeColor = (color, percent) ->
    f = parseInt(color.slice(1), 16)
    t = (if percent < 0 then 0 else 255)
    p = (if percent < 0 then percent * -1 else percent)
    R = f >> 16
    G = f >> 8 & 0x00FF
    B = f & 0x0000FF
    '#' + (0x1000000 + (Math.round((t - R) * p) + R) * 0x10000 + (Math.round((t - G) * p) + G) * 0x100 + (Math.round((t - B) * p) + B)).toString(16).slice(1)

getLinePath = (startX, startY, endX, endY) ->
    'M' + startX + ' ' + startY + ' L' + endX + ' ' + endY

getLineAngle = (x1, y1, x2, y2) ->
    x = x1 - x2
    y = y1 - y2

    if (!x && !y)
        return 0

    return (180 + Math.atan2(-y, -x) * 180 / Math.PI + 360) % 360

getPreserveAspectRatio = (trackAlignment) ->
    switch trackAlignment
        when 'top-left'     then 'xMinYMin meet'
        when 'top'          then 'xMidYMin meet'
        when 'top-right'    then 'xMaxYMin meet'
        when 'left'         then 'xMinYMid meet'
        when 'center'       then 'xMidYMid meet'
        when 'right'        then 'xMaxYMid meet'
        when 'bottom-left'  then 'xMinYMax meet'
        when 'bottom'       then 'xMidYMax meet'
        when 'bottom-right' then 'xMaxYMax meet'

angular.bootstrap document, [app.name]
