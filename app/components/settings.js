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
var settings_service_1 = require('../services/settings-service');
var Settings = (function () {
    function Settings(settingsService) {
        this._settings = settingsService.getSettings();
    }
    Settings.prototype.afterViewInit = function () {
        if (!Settings.popoverInitialized) {
            this.initializePopover();
            Settings.popoverInitialized = true;
        }
        if (!Settings.spectrumInitialized) {
            this.initializeSpectrum();
            Settings.spectrumInitialized = true;
        }
    };
    Settings.prototype.initializePopover = function () {
        jQuery('[data-toggle="popover"]').popover({
            container: 'body',
            html: true,
            template: "<div class=\"popover overlay-settings\" role=\"tooltip\">\n                <div class=\"arrow\"></div>\n                <h3 class=\"popover-title\"></h3>\n                <div class=\"popover-content\"></div>\n                </div>\n            "
        });
    };
    Settings.prototype.initializeSpectrum = function () {
        var spectrumOptions = {
            preferredFormat: 'hex6',
            showInput: true,
            showInitial: true,
            appendTo: 'form.overlay-settings'
        };
        var allowEmptyOptions = jQuery.extend({}, spectrumOptions, { allowEmpty: true });
        jQuery('input.colorpicker:not(.allow-empty)').spectrum(spectrumOptions);
        jQuery('input.colorpicker.allow-empty').spectrum(allowEmptyOptions);
    };
    Settings = __decorate([
        angular2_1.Component({
            selector: 'settings',
            providers: [settings_service_1.SettingsService]
        }),
        angular2_1.View({
            templateUrl: 'app/templates/settings.html',
            directives: [angular2_1.FORM_DIRECTIVES, angular2_1.CORE_DIRECTIVES]
        }), 
        __metadata('design:paramtypes', [settings_service_1.SettingsService])
    ], Settings);
    return Settings;
})();
exports.Settings = Settings;
