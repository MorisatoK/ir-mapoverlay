/// <reference path="../../libs/typings/tsd.d.ts" />

import { Component, View, FORM_DIRECTIVES, CORE_DIRECTIVES } from 'angular2/angular2';
import { SettingsService } from '../services/settings-service';

@Component({
    selector: 'settings',
    providers: [SettingsService]
})

@View({
    templateUrl: 'app/templates/settings.html',
    directives: [FORM_DIRECTIVES, CORE_DIRECTIVES]
})

export class Settings {
    static popoverInitialized: boolean;
    static spectrumInitialized: boolean;
    private _settings;

    constructor(settingsService: SettingsService) {
        this._settings = settingsService.getSettings();
    }

    afterViewInit() {
        if (!Settings.popoverInitialized) {
            this.initializePopover();
            Settings.popoverInitialized = true;
        }

        // needs to be initialized here because of chrome issues with native controls
        if (!Settings.spectrumInitialized) {
            this.initializeSpectrum();
            Settings.spectrumInitialized = true;
        }
    }

    initializePopover() {
        jQuery('[data-toggle="popover"]').popover({
            container: 'body',
            html: true,
            template: `<div class="popover overlay-settings" role="tooltip">
                <div class="arrow"></div>
                <h3 class="popover-title"></h3>
                <div class="popover-content"></div>
                </div>
            `
        });
    }

    initializeSpectrum() {
        var spectrumOptions: Object = {
            preferredFormat: 'hex6',
            showInput: true,
            showInitial: true,
            appendTo: 'form.overlay-settings'
        };

        var allowEmptyOptions: Object = jQuery.extend({},
            spectrumOptions,
            { allowEmpty: true }
        );

        jQuery('input.colorpicker:not(.allow-empty)').spectrum(spectrumOptions);
        jQuery('input.colorpicker.allow-empty').spectrum(allowEmptyOptions);
    }
}
