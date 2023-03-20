// Master manifest file for engine, so local app can require
// this one file, but get all our files -- and local app
// require does not need to change if we change file list.
//
// Note JQuery is required to be loaded for flot and blacklight_range_limit
// JS to work, expect host app to load it.


import 'flot/source/jquery.canvaswrapper.js'
import 'flot/source/jquery.colorhelpers.js'
import 'flot/source/jquery.flot.js'
import 'flot/source/jquery.flot.browser.js'
import 'flot/source/jquery.flot.saturated.js'
import 'flot/source/jquery.flot.drawSeries.js'
import 'flot/lib/jquery.event.drag.js'
import 'flot/source/jquery.flot.hover.js'
import 'flot/source/jquery.flot.uiConstants.js'
import 'flot/source/jquery.flot.selection.js'
import 'bootstrap-slider'

// Ensure that range_limit_shared is loaded first
import './blacklight_range_limit/range_limit_shared'
import './blacklight_range_limit/range_limit_plotting'
import './blacklight_range_limit/range_limit_slider'
import './blacklight_range_limit/range_limit_distro_facets'
