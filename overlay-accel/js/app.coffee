app = angular.module 'overlay-accel', [
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
        title = 'Accelerometer Overlay &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

app.controller 'SettingsCtrl', ($scope, localStorageService) ->
    defaultSettings =
        host: 'localhost:8182'
        fps: 15
        accelColor: '#FF3333'
        gaugeColor: '#111111'
        gaugeOutline: '#FFFFFF'
        gaugeOutlineAlpha: 15
        gaugeBorderRadius: 10

    $scope.isDefaultHost = document.location.host == defaultSettings.host

    $scope.settings = settings = localStorageService.get('settings') or {}
    settings.host ?= null
    settings.fps ?= defaultSettings.fps
    settings.accelColor ?= defaultSettings.accelColor
    settings.gaugeColor ?= defaultSettings.gaugeColor
    settings.gaugeOutline ?= defaultSettings.gaugeOutline
    settings.gaugeOutlineAlpha ?= defaultSettings.gaugeOutlineAlpha
    settings.gaugeBorderRadius ?= defaultSettings.gaugeBorderRadius

    $scope.saveSettings = saveSettings = ->
        settings.fps = Math.min 60, Math.max(1, settings.fps)
        localStorageService.set 'settings', settings
        updateURL()

    actualKeys = [
        'host'
        'fps'
        'accelColor'
        'gaugeColor'
        'gaugeOutline'
        'gaugeOutlineAlpha'
        'gaugeBorderRadius'
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
        $scope.url = "http://#{document.location.host}/ir-mapoverlay/overlay-accel/overlay.html\
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

angular.bootstrap document, [app.name]
