/// <reference path="../../libs/typings/tsd.d.ts" />
/// <reference path="../../libs/typings/settings-service.d.ts" />

import { Component, Injectable } from 'angular2/angular2';
import { RouteParams } from 'angular2/router';

let defaultSettings: SettingsService.ISettingsServiceSettings = {
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
    //driverGroups: [{ids: '12345,12367', color: '#00ff00'}, {ids: '54321', color: '#ff00ff'}]
}

@Injectable()
export class SettingsService {
    private _localStorageItemName: string = 'mapOverlaySettings';
    private _settings: SettingsService.ISettingsServiceSettings;
    private _routeParams: RouteParams;
    private _isDefaultHost: boolean;
    private _clrBrowser: string;

    constructor(routeParams: RouteParams) {
        this._routeParams = routeParams;
        this._isDefaultHost = location.host === defaultSettings.host;

        // first set default settings, then apply settings from localStorage
        // after that apply settings from query parameters (needed for direct
        // call to overlay later)
        this._settings = defaultSettings;
        this._readStorage();
        this._readParams();

        // update the URL once
        this._updateUrl();
    }

    getSettings(): Object {
        var exportSettings = {};

        _.assign(exportSettings, {
            options: this._settings,
            clrBrowser: this._clrBrowser,
            isDefaultHost: this._isDefaultHost
        })
        return exportSettings;
    }

    private _writeStorage(): void {
        localStorage.setItem(this._localStorageItemName, JSON.stringify(this._settings));
    }

    private _readStorage(): void {
        var localStorageSettings = JSON.parse(localStorage.getItem(this._localStorageItemName));

        if (!_.isNull(localStorageSettings))
            _.assign(this._settings, localStorageSettings);
    }

    private _readParams(): void {
        var queryParams = this._routeParams.params;

        if (_.isEmpty(queryParams))
            return;

        Object.keys(queryParams).forEach((k) => {
            queryParams[k] = decodeURIComponent(queryParams[k]);
        });

        _.assign(this._settings, queryParams);
    }

    private _updateUrl(): void {
        var params = this._serialize(this._settings);

        this._clrBrowser = 'http://' + location.host + '/#/overlay'; // get this from router?

        if (!_.isUndefined(params))
            this._clrBrowser += '?' + params;
    }

    private _serialize(object, prefix?): string {
        var str = [];
        for (var property in object) {
            if (object.hasOwnProperty(property)) {
                var k = prefix ? prefix + '[' + property + ']' : property,
                    v = object[property];

                if (this._settings[k] == defaultSettings[k])
                    return;

                str.push(typeof v == 'object' ?
                    this._serialize(v, k) :
                    encodeURIComponent(k) + '=' + encodeURIComponent(v));
            }
        }
        return str.join('&');
    }
}
