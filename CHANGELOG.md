# iRacing TrackOverlay & Accelerometer Changelog
### 1.7.10 - 2019-10-13

##### Track Overlay

* Updated SVG library
* Added overview of supported and tested tracks
* Add Circuit de Barcelona Catalunya
* Add new Silverstone Circuit
* Add new Charlotte Motor Speedway configs
* Add Sonoma Rallycross config
* Add Phoenix 2008 Rallycross config
* Add new Michigan Speedway
* Add new Pocono Raceway
* Add Centripetal Circuit
* Add Long Beach Tech Track
* Add The Bullring
* Add Myrtle Beach Speedway
* Add Limaland Motorsports Park
* Add Lucas Oil Raceway Rallycross config
* Add Knoxville Raceway
* Add The Dirt Track at Charlotte
* Add Kokomo Speedway
* Add Atlanta Motor Speedway Rallycross configs
* Add Chili Bowl
* Add Wild West Motorsports Park
* Add Wild Horse Pass Motorsports Park
* Add Fairbury Speedway

### 1.7.9 - 2019-01-20

Never officialy released

##### Track Overlay

Thanks to Søren Kruse who filed a pull request the following features have been added:

* Improved sizing and scaling of track maps
* Add Detroit Grand Prix at Belle Isle
* Add Charlotte Motor Speedway Roval
* Add Tsukuba Circuit configs

### 1.7.8 - 2017-09-30

##### Track Overlay

* Add Snetterton 300, 200 and 100 layouts
* Add Lanier National Speedway - Dirt
* Add USA International Speedway - Dirt
* Add Eldora Speedway
* Add Volusia Speedway Park
* Add Williams Grove Speedway

### 1.7.7 - 2017-04-28

##### Track Overlay

* Update to Angular 1.6

### 1.7.6 - 2016-09-07

##### Track Overlay

* New Tracks: Circuit des 24 Heures du Mans - 24 Heures du Mans and Historic layout

### 1.7.5 - 2016-06-07

##### Track Overlay

* New Tracks: Imola GP and Imola Moto

### 1.7.4 - 2016-05-05

##### Track Overlay

* updated svg.js to v2.3.1 that fixes the previous issues with track paths
* reverted previous changes to Monza GP trackmap
* added simple test page to compare native SVG drawing to svg.js drawing

### 1.7.3 - 2016-05-03

##### Track Overlay

* updated Monza GP trackmap to work around svg.js issue

### 1.7.2 - 2016-04-26

##### Track Overlay

* updated svg.min.js to the latest version

### 1.7.1 - 2016-01-07

##### Track Overlay

* iRacing changed the way some telemetry is reported for Nürburgring Touristenfahrten track. This updates the overlay to handle this change.

### 1.7.0 - 2015-12-12

##### Track Overlay

* New track: Southern National Motorsports Park
* New track: Nürburgring Grand-Prix-Strecke
* New track: Nürburgring Nordschleife
* New track: Nürburgring Combined
* New feature: Added support for separate start/finish lines (needed for NOS Touristenfahrten Bridge to Gantry variant)

Note: You might want to change the layout settings for the track stroke for the NOS otherwise lots of track details will be lost with a thick stroke.

### 1.6.0 - 2015-06-09

##### Track Overlay

* New track: Five Flags Speedway
* New feature: Driver/Team groups to highlight specific drivers and/or teams on map
* New option: "Circle Color" that can be used for the circle color of the drivers
* New option: "Player Highlight Color" that can be used for circle color of the player
* New option: "Number Highlight Color" that will be used for the player number and driver/team group numbers
* Removed option for "Carnumber Color". The color of the car number in the circle when no position is set will now be equal to "Position Color" or "Number Highlight Color" but transparent
* When custom circle colors or driver/team groups are used in multi-class races a separate bubble with the class color will be displayed
* Slight overhaul of the settings page
* Many under the hood changes and improvements

### 1.5.0 - 2015-05-06

##### Track Overlay

* Adds new option to display sector boundaries on map
* Fixes display bug for track maps with a seperate pitlane

### 1.4.2 - 2015-04-01

##### Track Overlay

* Replaces Raphael.js in favor of svg.js - should fix slow to no update issue on larger grids
* Clarification on settings page for rare cases when map is cut off
* Removes necessity of custom CSS in CLR Browser

### 1.4.1 - 2015-03-25

##### Track Overlay

* Fixes CarClassColor for Road Warrior Events
* Makes description of setting the dimensions of the overlay more clear
* Adds notice about multiple instances

### 1.4.0 - 2015-03-14

##### Track Overlay

* Adds Autodromo Nazionale Monza to overlays

### 1.3.0 - 2014-10-25

##### Track Overlay

* Fixes possible bug in iRacing when ClassPosition is reported as "-1"
* Fixes white driver bubbles in single class sessions
* Adds Gateway Motorsports Park to overlays

### 1.2.0 - 2014-09-28

##### General

* Dropped the full overlay with map and accelerometer implemented
* General refactoring and restructuring
* Added nice index pages with instructions to the overlays

##### Track Overlay

* Added Donington and new Phoenix
* Most parts of the map are now configurable
* Fixed multiclass car coloring

##### Accelerometer

* Most parts of the accelerometer are now configurable

### 1.1.0 - 2014-05-04

##### Track Overlay

* Improved visibility of the CamCar
* Improved class-color detection for driver circles
* Start line of tracks with extended start line should now be displayed correctly
* NEW: Offtracks are shown on the map

### 1.0.0 - 2014-04-27

Initial release
