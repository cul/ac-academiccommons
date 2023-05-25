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
import "jquery-ui/ui/widgets/sortable";
import '@fortawesome/fontawesome-free/js/all.js'
import 'datatables.net/js/jquery.dataTables.min';
import 'datatables.net-bs/js/dataTables.bootstrap.min';
import 'bootstrap/dist/js/bootstrap';

window.Bloodhound = require('corejs-typeahead');
import ClipboardJS from 'clipboard/dist/clipboard.min';
window.ClipboardJS = ClipboardJS;
import Dropzone from 'dropzone';
window.Dropzone = Dropzone;


require('@rails/ujs').start();
//require("@rails/activestorage").start();
import * as ActiveStorage from '@rails/activestorage';
window.ActiveStorage = ActiveStorage;

import * as Readmore from 'readmore-js';
window.Readmore = Readmore;

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight';
import '../src/blacklight_range_limit/blacklight_range_limit';


import "./application.scss"; // prompts webpack to include css packs

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
