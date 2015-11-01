var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var angular2_1 = require('angular2/angular2');
var router_1 = require('angular2/router');
var defaultSettings = {
    host: 'localhost:8182',
    fps: 15,
    trackColor: '#000000',
    trackWidth: 10,
    trackOutlineColor: '#FFFFFF',
    startFinishColor: '#FF0000',
    sectorColor: '#FFDA59',
    showSectors: false,
    driverCircle: 12,
    circleColor: '',
    driverHighlightWidth: 4,
    driverHighlightCam: '#4DFF51',
    driverHighlightOfftrack: '#FF0000',
    driverPosNum: '#000000',
    highlightNum: '#FFFFFF',
    playerHighlight: '',
    driverGroups: []
};
var SettingsService = (function () {
    function SettingsService(routeParams) {
        this._localStorageItemName = 'mapOverlaySettings';
        this._routeParams = routeParams;
        this._isDefaultHost = location.host === defaultSettings.host;
        this._settings = defaultSettings;
        this._readStorage();
        this._readParams();
        this._updateUrl();
    }
    SettingsService.prototype.getSettings = function () {
        var exportSettings = {};
        _.assign(exportSettings, {
            options: this._settings,
            clrBrowser: this._clrBrowser,
            isDefaultHost: this._isDefaultHost
        });
        return exportSettings;
    };
    SettingsService.prototype._writeStorage = function () {
        localStorage.setItem(this._localStorageItemName, JSON.stringify(this._settings));
    };
    SettingsService.prototype._readStorage = function () {
        var localStorageSettings = JSON.parse(localStorage.getItem(this._localStorageItemName));
        if (!_.isNull(localStorageSettings))
            _.assign(this._settings, localStorageSettings);
    };
    SettingsService.prototype._readParams = function () {
        var queryParams = this._routeParams.params;
        if (_.isEmpty(queryParams))
            return;
        Object.keys(queryParams).forEach(function (k) {
            queryParams[k] = decodeURIComponent(queryParams[k]);
        });
        _.assign(this._settings, queryParams);
    };
    SettingsService.prototype._updateUrl = function () {
        var params = this._serialize(this._settings);
        this._clrBrowser = 'http://' + location.host + '/#/overlay';
        if (!_.isUndefined(params))
            this._clrBrowser += '?' + params;
    };
    SettingsService.prototype._serialize = function (object, prefix) {
        var str = [];
        for (var property in object) {
            if (object.hasOwnProperty(property)) {
                var k = prefix ? prefix + '[' + property + ']' : property, v = object[property];
                if (this._settings[k] == defaultSettings[k])
                    return;
                str.push(typeof v == 'object' ?
                    this._serialize(v, k) :
                    encodeURIComponent(k) + '=' + encodeURIComponent(v));
            }
        }
        return str.join('&');
    };
    SettingsService = __decorate([
        angular2_1.Injectable(), 
        __metadata('design:paramtypes', [router_1.RouteParams])
    ], SettingsService);
    return SettingsService;
})();
exports.SettingsService = SettingsService;
