// Angular 2
import { bootstrap, Component, View, provide, CORE_DIRECTIVES } from 'angular2/angular2';
import { ROUTER_PROVIDERS, ROUTER_DIRECTIVES, RouteConfig, LocationStrategy, HashLocationStrategy } from 'angular2/router';

// Components
import { Home } from './components/home';
import { Settings } from './components/settings';
import { Overlay } from './components/overlay';

const VERSION: string = '2.0.0';

@Component({
    selector: 'map-overlay'
})

@View({
    directives: [ROUTER_DIRECTIVES, CORE_DIRECTIVES],
    templateUrl: 'app/templates/base.html'
})

@RouteConfig([
    { path: '/', redirectTo: '/home' },
    { path: '/home', as: 'Home', component: Home },
    { path: '/settings', as: 'Settings', component: Settings },
    { path: '/overlay', as: 'Overlay', component: Overlay }
])

export class MapOverlay {
    version: string;

    constructor() {
        this.version = VERSION;
    }

    isRouteActive(route: string) {
        return { active: location.hash.match(route) };
    }

    isNavigationHidden() {
        return location.hash.match('overlay');
    }
}

bootstrap(
    MapOverlay, [
        ROUTER_PROVIDERS,
        provide(LocationStrategy, { useClass: HashLocationStrategy })
    ]
);
