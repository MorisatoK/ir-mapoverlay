iRacing TrackOverlay & Accelerometer 
====================================

These are addons to the [iRacing Browser Apps by Mihail Latyshov](http://ir-apps.kutu.ru/) and are primarily ment to add more features to the existing overlay for first person streamers.

Track overlay
-------------

A stylized track map showing all cars and their position (car number if no time/position is set) on track or in pits. Tracks are based on [RivalTracker by Sam Hazim](https://github.com/SamHazim/RivalTracker) with many of them redrawn and missing tracks for iRacing added.

Accelerometer
-------------

Displays the lateral and longitudinal acceleration on a scale of 3G on the drivers car.

Usage
=====

1. Obviously you need the [iRacing Browser Server by Mihail Latyshov](http://ir-apps.kutu.ru/)
2. Download this repository as ZIP.
3. Extract contents of the ZIP into your iR Browser Server "apps" directory

The two addons available are **overlay-map** and **overlay-accel**.

overlay-map
-----------

The map doesn't need to be configured but can be styled via the according JS and CSS files. Add it to OBS just like the original stream-overlay but with the URL pointing to `http://localhost:8182/ir-mapoverlay/overlay-map/` and a size of 420x324px (default).

overlay-accel
-------------

The accelerometer doesn't need to be configured but can be styled via the according JS and CSS files. Add it to OBS just like the original stream-overlay but with the URL pointing to `http://localhost:8182/ir-mapoverlay/overlay-accel/` and a size of 130x130px (default).

Known bugs and limitations
==========================

* Tested on most if not all of the road tracks and some of the ovals I own - being a road guy this leaves most of the ovals and some road tracks untested so YMMV.
* On some tracks the pit road is displayed on map but this is solely cosmetic.
* Map works live and in replays but not when watching the replay in a live session.
* The accelerometer only works when you are driving the car. This is intended.
