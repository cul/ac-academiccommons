/* eslint no-console:0 */
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
require.context('../images', true);
require.context('../assets', true)
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import 'jquery';
import 'readmore-js/readmore';
import 'social-share-button';
import 'dropzone';
import 'clipboard/dist/clipboard.min';
import 'font-awesome/css/font-awesome.css';
import 'datatables.net/js/jquery.dataTables.min';
import 'datatables.net-bs/js/dataTables.bootstrap.min';
import 'mediaelement/full'
import 'mediaelement/build/mediaelementplayer.min.css';
import 'bootstrap/dist/js/bootstrap';

require('@rails/ujs').start()
require("@rails/activestorage").start();
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
//import 'blacklight_range_limit';

import "./stylesheets.scss"; // prompts webpack to include css packs

import '../src/admin/enable-optional-fields';
import '../src/admin/datatables';
import '../src/admin/usage-statistics';
import '../src/copy-to-clipboard';
import '../src/duplicate-input-fields';
import '../src/flash-messages-for-ajax-requests';
import '../src/jquery-ui-sortable';
import '../src/read-more';
import '../src/skip-link-focus-fix';
import '../src/sticky-sidebar';
import '../src/smooth-scroll';
import '../src/upload/file-upload';
import '../src/upload/add-creator';
import '../src/upload/license-options';
import '../src/upload/disable-form';
import '../src/upload/author-reorder';
import '../src/mediaelement'


$(document).ready(Blacklight.onload);
