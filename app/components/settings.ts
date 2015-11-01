/// <reference path="../../libs/typings/tsd.d.ts" />

import { Component, View } from 'angular2/angular2';

@Component({
    selector: 'settings'
})

@View({
    templateUrl: 'app/templates/settings.html'
})

export class Settings {
    static popoverInitialized: boolean;

    afterViewInit() {
        if (!Settings.popoverInitialized) {
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
            Settings.popoverInitialized = true;
        }
    }
}
