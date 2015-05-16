app = angular.module 'overlay-map', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'LocalStorageModule'
    'kutu.markdown'
    'colorpicker.module'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
        .when '/settings',
            templateUrl: 'tmpl/settings.html'
            controller: 'SettingsCtrl'
            title: 'Settings'
        .otherwise redirectTo: '/'

app.config (localStorageServiceProvider) ->
    localStorageServiceProvider.setPrefix app.name

app.run ($rootScope, $sce) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Track Map Overlay &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

app.controller 'SettingsCtrl', ($scope, localStorageService) ->
    defaultSettings =
        host: 'localhost:8182'
        fps: 15
        trackColor: '#000000'
        trackWidth: 10
        trackOutlineColor: '#FFFFFF'
        startFinishColor: '#FF0000'
        sectorColor: '#FFDA59'
        showSectors: false
        driverCircle: 12
        driverHighlightWidth: 4
        driverHighlightCam: '#4DFF51'
        driverHighlightOfftrack: '#FF0000'
        driverPosNum: '#000000'
        highlightNum: '#FFFFFF'
        driverGroups: []

    $scope.isDefaultHost = document.location.host == defaultSettings.host

    $scope.settings = settings = localStorageService.get('settings') or {}
    settings.host ?= null
    settings.fps ?= defaultSettings.fps
    settings.trackColor ?= defaultSettings.trackColor
    settings.trackWidth ?= defaultSettings.trackWidth
    settings.trackOutlineColor ?= defaultSettings.trackOutlineColor
    settings.startFinishColor ?= defaultSettings.startFinishColor
    settings.sectorColor ?= defaultSettings.sectorColor
    settings.showSectors ?= defaultSettings.showSectors
    settings.driverCircle ?= defaultSettings.driverCircle
    settings.driverHighlightWidth ?= defaultSettings.driverHighlightWidth
    settings.driverHighlightCam ?= defaultSettings.driverHighlightCam
    settings.driverHighlightOfftrack ?= defaultSettings.driverHighlightOfftrack
    settings.driverPosNum ?= defaultSettings.driverPosNum
    settings.highlightNum ?= defaultSettings.highlightNum
    settings.driverGroups ?= defaultSettings.driverGroups

    $scope.saveSettings = saveSettings = ->
        settings.fps = Math.min 60, Math.max(1, settings.fps)
        localStorageService.set 'settings', settings
        updateURL()

    actualKeys = [
        'host'
        'fps'
        'trackColor'
        'trackWidth'
        'trackOutlineColor'
        'startFinishColor'
        'sectorColor'
        'showSectors'
        'driverCircle'
        'driverHighlightWidth'
        'driverHighlightCam'
        'driverHighlightOfftrack'
        'driverPosNum'
        'highlightNum'
    ]

    updateURL = ->
        params = []
        for k, v of settings
            if k of defaultSettings and v == defaultSettings[k]
                continue
            if k == 'host' and (not settings.host or $scope.isDefaultHost)
                continue
            if k in actualKeys
                params.push "#{k}=#{encodeURIComponent v}"
            if k == 'driverGroups'
                for group in v
                    if group.ids == '' or group.color == ''
                        continue
                    params.push "dGrp=#{encodeURIComponent group.ids}"
                    params.push "dGrpClr=#{encodeURIComponent group.color}"

        $scope.url = "http://#{document.location.host}/ir-mapoverlay/overlay-map/overlay.html\
            #{if params.length then '#?' + params.join '&' else ''}"
    updateURL()

    $scope.changeURL = ->
        params = $scope.url and $scope.url.search('#?') != -1 and $scope.url.split('#?', 2)[1]
        if not params
            return
        for p in $scope.url.split('#?', 2)[1].split '&'
            [k, v] = p.split '=', 2
            if k not of settings
                continue
            nv = Number v
            if not isNaN nv and v.length == nv.toString().length
                v = Number(v)
            settings[k] = v
        saveSettings()

    $scope.sanitizeDriverGroups = sanitizeDriverGroups = ->
        for group in settings.driverGroups
            group.ids = group.ids.replace /,{2,}/g, ','
            group.ids = group.ids.replace /[^0-9,]/g, ''
        saveSettings()

    $scope.trimComma = trimComma = ->
        for group in settings.driverGroups
            if group.ids.charAt(group.ids.length - 1) == ','
                group.ids = group.ids.slice 0, -1
        saveSettings()

    $scope.addGroup = ->
        settings.driverGroups.push {'ids':'', 'color': ''}
      
    $scope.removeGroup = (element) ->
        settings.driverGroups.splice this.$index, 1
        saveSettings()

angular.bootstrap document, [app.name]
