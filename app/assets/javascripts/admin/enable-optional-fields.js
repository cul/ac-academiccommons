// Enabling optional fields for Email Author Reports form

$(document).ready(function(){
  if ($('body').is('.admin-email-author-reports.new')) {

    // When sending report to single author, enable uni field.
    $('[name="email_author_reports_form[reports_for]"]').change(function(){
      var uniField = $('[name="email_author_reports_form[uni]"]')
      if (this.value == 'one'){
        uniField.prop("disabled", false);
      } else {
        uniField.prop("disabled", true);
      };
    });

    // When sending all emails to a single email address, enable email field.
    $('[name="email_author_reports_form[deliver]"]').change(function(){
      var uniField = $('[name="email_author_reports_form[email]"]')
      if (this.value == 'all_reports_to_one_email'){
        uniField.prop("disabled", false);
      } else {
        uniField.prop("disabled", true);
      };
    });

  };
});
