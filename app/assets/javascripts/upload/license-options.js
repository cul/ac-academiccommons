// Change license options based on the copyright status that is selected.

$(document).ready(function(){
  function addLicenseDropdown(div, licenses, prompt) {
    var s = $('<select skip_default_ids="false" allow_method_names_outside_object="true" name="deposit[license]" id="deposit_license">');

    if (prompt != undefined) {
      $('<option/>', { text: prompt }).appendTo(s)
    }

    var hiddenInput = $('input[type="hidden"][name="deposit[license]"]')

    for (i = 0; i < licenses.length; ++i) {
      option = $('<option />', {
        value: licenses[i],
        text: licenses[i],
        selected: (hiddenInput.attr('value') === licenses[i]) ? 'selected' : null
      }).appendTo(s);
    }

    s.appendTo(div);
  }

  $('form#upload select#deposit_rights_statement').change(function() {
    if ($(this).val() != 'No Copyright' && $(this).val() != 'In Copyright'){
      return;
    }

    var div = $('form#upload div#use-by-others')

    // Remove any previous selection.
    var license_select = $('select[name="deposit[license]"]')
    if (license_select.length) {
      $(license_select).remove();
    }

    // If this label isn't present, add it.
    if ($('label[for=deposit_license]').length == 0) {
      $(div).append($('<div class="animated fadeIn"><label for="deposit_license">Use by Others</label><p class="note">Please confirm how you wish others to re-use your deposit. For more information about how licenses work, see <a href="https://copyright.columbia.edu/basics/copyright-quick-guide.html">Columbia University Library&#39;s Copyright Advisory Service&#39;s Copyright Quick Guide</a>. For specific licensing terms and conditions on re-use of your deposit for each of the options in the drop-down menu below, see <a href="https://creativecommons.org/">Creative Commons</a>.</p><p class="note">You can choose not to set any specific licensing terms and conditions and if so, others can only re-use your deposit as determined by domestic and international copyright laws. If you choose not to set specific licensing terms for re-use, then you must choose the option "All Rights Reserved" from the drop-down menu below.</p><p class="note">By making this choice, you confirm that you have the authority to do so.</p></div>'))
    }

    // Add dropdown with appropriate list of license options depending on
    //copyright selection
    if ($(this).val() === 'No Copyright') {
      addLicenseDropdown(div, ['CC0'])
    } else {
      var licenses = [
        'Attribution (CC BY)',
        'Attribution-ShareAlike (CC BY-SA)',
        'Attribution-NoDerivs (CC BY-ND)',
        'Attribution-NonCommercial (CC BY-NC)',
        'Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)',
        'Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)',
        'Use by others as provided for by copyright laws - All rights reserved'
      ];

      addLicenseDropdown(div, licenses, 'Choose how others may use this work')
    }
  }).change();
});
