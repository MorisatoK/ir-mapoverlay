window.app = angular.module 'overlay-accel', [
    'ngAnimate'
    'ngSanitize'
]

app.config ($locationProvider) ->
    $locationProvider.hashPrefix ''

app.service 'config', ($location) ->
    vars = $location.search()

    fps = parseInt(vars.fps) or 15
    fps = Math.max 1, Math.min 60, fps

    gaugeOutlineAlpha = parseInt(vars.gaugeOutlineAlpha) or 15
    gaugeOutlineAlpha = Math.max 0, Math.min 100, gaugeOutlineAlpha

    gaugeBorderRadius = parseInt(vars.gaugeBorderRadius) or 10
    gaugeBorderRadius = Math.max 0, Math.min 10, gaugeBorderRadius

    host: vars.host or 'localhost:8182'
    fps: fps

    accelColor: vars.accelColor or '#FF3333'
    gaugeColor: vars.gaugeColor or '#111111'
    gaugeOutline: vars.gaugeOutline or '#FFFFFF'
    gaugeOutlineAlpha: gaugeOutlineAlpha
    gaugeBorderRadius: gaugeBorderRadius

    requestParams: [
        'IsOnTrack'
        'LatAccel'
        'LongAccel'
    ]
    requestParamsOnce: [
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
        $rootScope.$apply()

    return ir.data

app.run (config) ->
    gaugeBorderStyle = '5px solid ' + convertHex(config.gaugeOutline, config.gaugeOutlineAlpha)
    gaugeBorderRadius = config.gaugeBorderRadius + 'px'

    styleElement = document.createElement('style')
    styleElement.setAttribute('type', 'text/css')
    styleElement.appendChild(document.createTextNode('')) # Webkit hack
    document.head.appendChild(styleElement)

    styleSheet = styleElement.sheet
    styleSheet.insertRule('\
        .lat-accel, .long-accel { \
            background: ' + config.accelColor + ';\
        }', 0);
    styleSheet.insertRule('\
        .lat-gauge-top, .lat-gauge-bottom, .long-gauge-left, .long-gauge-right, .gauge-center {\
            background: ' + config.gaugeColor + ';\
        }', 0);
    styleSheet.insertRule('\
        .lat-gauge-top, .lat-gauge-bottom {\
            border-left: ' + gaugeBorderStyle + ';\
            border-right: ' + gaugeBorderStyle + ';\
        }', 0);
    styleSheet.insertRule('\
        .lat-gauge-top {\
            border-top: ' + gaugeBorderStyle + ';\
            border-top-left-radius: ' + gaugeBorderRadius + ';\
            border-top-right-radius: ' + gaugeBorderRadius + ';\
        }', 0);
    styleSheet.insertRule('\
        .lat-gauge-bottom {\
            border-bottom: ' + gaugeBorderStyle + ';\
            border-bottom-left-radius: ' + gaugeBorderRadius + ';\
            border-bottom-right-radius: ' + gaugeBorderRadius + ';\
        }', 0);
    styleSheet.insertRule('\
        .long-gauge-left, .long-gauge-right {\
            border-top: ' + gaugeBorderStyle + ';\
            border-bottom: ' + gaugeBorderStyle + ';\
        }', 0);
    styleSheet.insertRule('\
        .long-gauge-left {\
            border-left: ' + gaugeBorderStyle + ';\
            border-top-left-radius: ' + gaugeBorderRadius + ';\
            border-bottom-left-radius: ' + gaugeBorderRadius + ';\
        }', 0);
    styleSheet.insertRule('\
        .long-gauge-right {\
            border-right: ' + gaugeBorderStyle + ';\
            border-top-right-radius: ' + gaugeBorderRadius + ';\
            border-bottom-right-radius: ' + gaugeBorderRadius + ';\
        }', 0);

app.controller 'CarCtrl', ($scope, $element, iRData) ->
    $scope.ir = iRData
    $scope.$watch 'ir.IsOnTrack', (n, o) ->
        $element.toggleClass 'ng-hide', not n

app.directive 'appLatAccel', (iRData) ->
    link: (scope, element, attrs) ->
        ir = iRData

        scope.$watch 'ir.LatAccel', (n, o) ->
            percent = accelToGToPercent ir.LatAccel
            if percent < 0
                element.css
                    left: percent + '%'
                    width: (percent*-1) + 20 + '%'
            else if percent > 0
                element.css
                    left: 0 + '%'
                    width: percent + 20 + '%'

app.directive 'appLongAccel', (iRData) ->
    link: (scope, element, attrs) ->
        ir = iRData

        scope.$watch 'ir.LongAccel', (n, o) ->
            percent = accelToGToPercent ir.LongAccel
            if percent < 0
                element.css
                    top: percent + '%'
                    height: (percent*-1) + 20 + '%'
            else if percent > 0
                element.css
                    top: 0 + '%'
                    height: percent + 20 + '%'

app.filter 'accel', -> accelToGToPercent

accelToGToPercent = (accel) ->
    Math.round((100*(accel/9.81))/3) # Percentage on a scale of 3G

convertHex = (hex, opacity) ->
    hex = hex.replace('#', '')
    r = parseInt(hex.substring(0, 2), 16)
    g = parseInt(hex.substring(2, 4), 16)
    b = parseInt(hex.substring(4, 6), 16)

    result = 'rgba('+r+','+g+','+b+','+opacity/100+')'

angular.bootstrap document, [app.name]
