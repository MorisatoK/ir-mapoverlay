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
var Settings = (function () {
    function Settings() {
    }
    Settings.prototype.afterViewInit = function () {
        if (!Settings.popoverInitialized) {
            jQuery('[data-toggle="popover"]').popover({
                container: 'body',
                html: true,
                template: "<div class=\"popover overlay-settings\" role=\"tooltip\">\n                    <div class=\"arrow\"></div>\n                    <h3 class=\"popover-title\"></h3>\n                    <div class=\"popover-content\"></div>\n                    </div>\n                "
            });
            Settings.popoverInitialized = true;
        }
    };
    Settings = __decorate([
        angular2_1.Component({
            selector: 'settings'
        }),
        angular2_1.View({
            templateUrl: 'app/templates/settings.html'
        }), 
        __metadata('design:paramtypes', [])
    ], Settings);
    return Settings;
})();
exports.Settings = Settings;
