window.app = angular.module 'app', [
    'ngAnimate'
    'ngSanitize'
]

app.service 'iRData', ($rootScope, $location) ->
    fps = parseInt($location.search().fps) || 10
    fps = Math.max 1, Math.min 60, fps
    ir = new IRacing \
        # request params
        [
            'IsOnTrack'
            'LatAccel'
            'LongAccel'
        ],
        # request params once
        [
        ],
        fps

    ir.onConnect = ->
        ir.data.connected = true
        $rootScope.$apply()

    ir.onDisconnect = ->
        ir.data.connected = false
        $rootScope.$apply()

    ir.onUpdate = (keys) ->
        $rootScope.$apply()

    return ir.data

app.controller 'CarCtrl', ($scope, $element, iRData) ->
    $scope.ir = iRData
    $scope.$watch 'ir.IsOnTrack', (n, o) ->
        $element.toggleClass 'ng-hide', not n

##### Accelerometer

# Controller for testing when not on track/live etc.
app.controller 'NoCarCtrl', ($scope, $element, iRData) ->
    $scope.ir = iRData

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

##### /Accelerometer

angular.bootstrap document, [app.name]
