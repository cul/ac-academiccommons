/* eslint no-console:0 */
// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log('Vite ⚡️ Rails')

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

console.log('Visit the guide for more information: ', 'https://vite-ruby.netlify.app/guide/rails')

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

/////////////////////////// copy of packs/application.js (webpacker config):
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// import.meta.glob('../images/**/*', { eager: true });
// import.meta.glob('../assets/**/*', { eager: true });


// import CSS
// TODO : needed?
// not needed in vite
// import "./application.scss"; // prompts webpack to include css packs


// jQuery - must be global for legacy plugins
// import $ from 'jquery'
// window.$ = window.jQuery = $
// import '../src/jquery-setup.js';


// import '../src/jquery-setup.js'
// import jQuery from 'jquery';
// window.$ = window.jQuery = jQuery;


// import "jquery-ui/ui/widgets/mouse"; 
// import 'datatables.net-bs/js/dataTables.bootstrap.min';
// import 'datatables.net/js/jquery.dataTables.min';


// Issues with vite: https://github.com/jquery/jquery-ui/issues/2123#event-13186348290
// Workaround w/await (from here https://github.com/vitejs/vite/discussions/9415#discussioncomment-3959724):
// Instead, we will ready the env in this file (set the window. variables):
import './jquery.js'

// Vite will minify the js for us (no need to import the .min)
// import  'datatables.net-bs/js/dataTables.bootstrap.min';
// import 'datatables.net/js/jquery.dataTables.min';
import 'datatables.net'
import 'datatables.net-bs4'

// NB this is still being worked on--sortable is being called on a datatable object, so i need to fix datatables first
// we just need sortable, but let's bring in the whole jquery-ui
// it is only used on the element in the new upload view (with id creator-list)
import 'jquery-ui-dist/jquery-ui';

// Loading blacklight -- depends on the version! (https://github.com/projectblacklight/blacklight/issues/3050)
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight';

// We are waiting until the vite migration is complete to add the range limit slider back --- ACHYDRA 1022
// import '../src/blacklight_range_limit/blacklight_range_limit';

import '@fortawesome/fontawesome-free/js/all.js'

// Bootstrap and dependencies
import Popper from 'popper.js'
window.Popper = Popper
import 'bootstrap';

// NOTE : are we using Bloodhound? ask JAck
// import Bloodhound from 'corejs-typeahead'; window.Bloodhound = Bloodhound

// import Dropzone from 'dropzone';
// window.Dropzone = Dropzone;

import Railsujs from '@rails/ujs';
Railsujs.start();

import * as ActiveStorage from '@rails/activestorage';
ActiveStorage.start()
// maybe -- just import within file-upload.js
// window.ActiveStorage = ActiveStorage;

// TODO : this was hard to test and so I haven't yet :3
// import * as Readmore from 'readmore-js';
// window.Readmore = Readmore;

// Custom JS modules
import '../src/admin/enable-optional-fields';
import '../src/admin/datatables'; 
import '../src/admin/usage-statistics';
import '../src/copy-to-clipboard';
import '../src/duplicate-input-fields';
import '../src/flash-messages-for-ajax-requests';
import '../src/read-more';
import '../src/skip-link-focus-fix';
import '../src/upload/file-upload';
import '../src/upload/add-creator';
import '../src/upload/current-student';
import '../src/upload/disable-form';
import '../src/upload/author-reorder';
import { videoReady } from "../src/videojs.js";
$(document).ready(videoReady);

$(document).ready(Blacklight.onload);

if ($.fn.DataTables) {
    console.log("datatables available")
} else {
    console.log("DATATABLES NOT AVBAILABLEBLBELLBEB")
}
// $(document).ready(function(){
//   // No ordering applied by DataTables during initialisation
//   // Enable horizontal scrolling
//   $('.datatables').DataTable({
//     "order": [],
//     "scrollX": true
//   });
// });

