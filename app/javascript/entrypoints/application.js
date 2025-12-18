/* eslint no-console:0 */

// This file is compiled by Vite automatically, and is used as the entrypoint to
// create the bundle.
// To reference this file, add the following to the <head>
// section of the base layout template (so that it is present on every page):
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
//
// For AC, we added these in base.html.erb and embed.html.erb. We also add the
// following to bring in the CSS bundle!:
//  <%= vite_stylesheet_tag 'application.scss' %>
//

// Issues with vite: https://github.com/jquery/jquery-ui/issues/2123#event-13186348290
// We will initialized jquery for the browser in this file (import and set the window. variables):
import './jquery.js';

import 'datatables.net';
import 'datatables.net-bs4'

// we just need sortable, but let's bring in the whole jquery-ui
// it is only used on the element in the new upload view (with id creator-list)
import 'jquery-ui-dist/jquery-ui';

// Loading blacklight -- what to import depends on the version! (https://github.com/projectblacklight/blacklight/issues/3050)
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight';

// We are waiting until the vite migration is complete to add the range limit slider back --- ACHYDRA 1022
// import '../src/blacklight_range_limit/blacklight_range_limit';

import '@fortawesome/fontawesome-free/js/all.js';

// Bootstrap and dependencies
import Popper from 'popper.js';
window.Popper = Popper;
import 'bootstrap';

// n.b.--we should consider migrating to turbo instead of UJS" https://guides.rubyonrails.org/v7.2/working_with_javascript_in_rails.html#replacements-for-rails-ujs-functionality
// See ACHYDRA-1032
// Also, momento mori: https://github.com/rails/rails/pull/50535
import Rails from '@rails/ujs';
// Allegedly, there is no need to call start with this config/bundler: https://github.com/rails/rails/issues/49499#issuecomment-1749092948
// ... and nevertheless, we must do it for UJS to work!
Rails.start();

// We need to explicitly start Turbolinks if we import it 
// https://github.com/turbolinks/turbolinks?tab=readme-ov-file#installation-using-npm
// N.b. This will be replaced by hotwire eventually, see ACHYDRA-1032
import Turbolinks from 'turbolinks';
Turbolinks.start();

import * as ActiveStorage from '@rails/activestorage';
ActiveStorage.start();
window.ActiveStorage = ActiveStorage;

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