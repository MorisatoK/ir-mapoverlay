// Angular 2
import { bootstrap, Component, View, bind } from 'angular2/angular2';
import { ROUTER_PROVIDERS, ROUTER_DIRECTIVES, RouteConfig, LocationStrategy, Location, HashLocationStrategy } from 'angular2/router';

// Components
import { Home } from './components/home';
import { Settings } from './components/settings';
import { Overlay } from './components/overlay';

const VERSION: string = '2.0.0';

@Component({
    selector: 'map-overlay'
})

@View({
    directives: [ROUTER_DIRECTIVES],
    templateUrl: 'app/templates/base.html'
})

@RouteConfig([
    { path: '/', as: 'Home', component: Home },
    { path: '/settings', as: 'Settings', component: Settings },
    { path: '/overlay', as: 'Overlay', component: Overlay }
])

export class MapOverlay {
    version: string;

    constructor() {
        this.version = VERSION;
    }
}

bootstrap(
    MapOverlay,
    [ROUTER_PROVIDERS, bind(LocationStrategy).toClass(HashLocationStrategy)]
);
