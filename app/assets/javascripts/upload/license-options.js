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
      $(div).append($('<div class="animated fadeIn"><label for="deposit_license">Use by Others</label><p class="note">For more information on how licenses work and the options below, see our <a href="https://copyright.columbia.edu/basics/copyright-quick-guide.html">Copyright Quick Guide</a>. For information on specific licensing terms as provided for in the options below, see <a href="https://creativecommons.org/">Creative Commons</a>.</p><p class="note"><em>By making a selection from the menu below I confirm that I have the authority to do so.</em></p></div>'))
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
