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
var home_1 = require('./components/home');
var settings_1 = require('./components/settings');
var overlay_1 = require('./components/overlay');
var VERSION = '2.0.0';
var MapOverlay = (function () {
    function MapOverlay() {
        this.version = VERSION;
    }
    MapOverlay.prototype.isRouteActive = function (route) {
        return { active: location.hash.match(route) };
    };
    MapOverlay.prototype.isNavigationHidden = function () {
        return location.hash.match('overlay');
    };
    MapOverlay = __decorate([
        angular2_1.Component({
            selector: 'map-overlay'
        }),
        angular2_1.View({
            directives: [router_1.ROUTER_DIRECTIVES, angular2_1.CORE_DIRECTIVES],
            templateUrl: 'app/templates/base.html'
        }),
        router_1.RouteConfig([
            { path: '/', redirectTo: '/home' },
            { path: '/home', as: 'Home', component: home_1.Home },
            { path: '/settings', as: 'Settings', component: settings_1.Settings },
            { path: '/overlay', as: 'Overlay', component: overlay_1.Overlay }
        ]), 
        __metadata('design:paramtypes', [])
    ], MapOverlay);
    return MapOverlay;
})();
exports.MapOverlay = MapOverlay;
angular2_1.bootstrap(MapOverlay, [
    router_1.ROUTER_PROVIDERS,
    angular2_1.provide(router_1.LocationStrategy, { useClass: router_1.HashLocationStrategy })
]);
