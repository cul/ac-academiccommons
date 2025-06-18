// Enabling optional fields for Email Author Reports form and Usage Statistics Report

$(document).ready(function(){
  if ($('body').is('.blacklight-email_author_reports')) {

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

  if ($('body').is('.blacklight-contact_authors')) {

    // When sending to specific authors, enable unis field
    $('[name="contact_authors_form[send_to]"]').change(function(){
      console.log( ' the value of the field is this value right here: ' + this.value)
      var unisField = $('name="contact_authors_form[unis]"')
      if (this.value == 'specific'){
        unisField.prop('disabled', false)
      } else {
        unisField.prop('disabled', true)
      }
    });

  };
  
  if ($('body').is('.blacklight-usage_statistics_reports')) {

    // When filtering stats by date, enable start and end date fields.
    $('[name="usage_statistics_reports_form[time_period]"]').change(function(){
      var fields = [
        '[name="usage_statistics_reports_form[start_date][month]"]',
        '[name="usage_statistics_reports_form[start_date][year]"]',
        '[name="usage_statistics_reports_form[end_date][month]"]',
        '[name="usage_statistics_reports_form[end_date][year]"]'
      ];
      var disabled = this.value != 'date_range';

      $.each(fields, function(index, value){
        $(value).prop("disabled", disabled);
      });
    });

    // When displaying stats month-by-month, disable order field.
    $('[name="usage_statistics_reports_form[display]"]').change(function(){
      var field = $('[name="usage_statistics_reports_form[order]"]');
      var disabled = this.value == 'month_by_month';
      
      field.prop("disabled", disabled);
    });
  };
});
