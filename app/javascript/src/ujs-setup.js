// n.b.--we should consider migrating to turbo instead of UJS" https://guides.rubyonrails.org/v7.2/working_with_javascript_in_rails.html#replacements-for-rails-ujs-functionality
// See ACHYDRA-1032
// Also, momento mori: https://github.com/rails/rails/pull/50535
import Rails from '@rails/ujs';
// Allegedly, there is no need to call start with this config/bundler: https://github.com/rails/rails/issues/49499#issuecomment-1749092948
// ... and nevertheless, we must do it for UJS to work!
Rails.start();

// NOTE: When ACHYDRA-1032 is complete, we can remove the two event listeners below because
// Hotwire/Turbo should automatically refresh form CSRF tokens.  After we switch to Hotwire/Turbo,
// make sure to test out https://academiccommons-dev.library.columbia.edu/upload/new
// to make sure we don't enounter any CSRF-related submission issues.
// document.addEventListener('DOMContentLoaded', () => {
//   document.addEventListener('turbo:load', Rails.refreshCSRFTokens);
// });
