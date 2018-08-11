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
        value: licenses[i].value,
        text: licenses[i].text,
        selected: (hiddenInput.attr('value') === licenses[i].value) ? 'selected' : null
      }).appendTo(s);
    }

    s.appendTo(div);
  }

  $('form#upload select#deposit_rights').change(function() {
    var inCopyright = 'http://rightsstatements.org/vocab/InC/1.0/';
    var noCopyright = 'http://rightsstatements.org/vocab/NoC-US/1.0/';

    if ($(this).val() != inCopyright && $(this).val() != noCopyright){
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
      $(div).append($('<div class="animated fadeIn"><label for="deposit_license" class="control-label">Use by Others*</label><p class="note">Please confirm how you wish others to re-use your deposit. For more information about how licenses work, see <a href="https://copyright.columbia.edu/basics/copyright-quick-guide.html">Columbia University Library&#39;s Copyright Advisory Service&#39;s Copyright Quick Guide</a>. For specific licensing terms and conditions on re-use of your deposit for each of the options in the drop-down menu below, see <a href="https://creativecommons.org/">Creative Commons</a>.</p><p class="note">You can choose not to set any specific licensing terms and conditions and if so, others can only re-use your deposit as determined by domestic and international copyright laws. If you choose not to set specific licensing terms for re-use, then you must choose the option "All Rights Reserved" from the drop-down menu below.</p><p class="note">By making this choice, you confirm that you have the authority to do so.</p></div>'))
    }

    // Add dropdown with appropriate list of license options depending on
    //copyright selection
    if ( $(this).val() === noCopyright ) {
      var licenses = [{ text: 'CC0', value: 'https://creativecommons.org/publicdomain/zero/1.0/' }];
    } else {
      var licenses = [
        { text: 'Use by others as provided for by copyright laws - All rights reserved', value: '' },
        { text: 'Attribution (CC BY)', value: 'https://creativecommons.org/licenses/by/4.0/' },
        { text: 'Attribution-ShareAlike (CC BY-SA)', value: 'https://creativecommons.org/licenses/by-sa/4.0/' },
        { text: 'Attribution-NoDerivs (CC BY-ND)', value: 'https://creativecommons.org/licenses/by-nd/4.0/' },
        { text: 'Attribution-NonCommercial (CC BY-NC)', value: 'https://creativecommons.org/licenses/by-nc/4.0/' },
        { text:'Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)', value: 'https://creativecommons.org/licenses/by-nc-sa/4.0/'},
        { text: 'Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)', value: 'https://creativecommons.org/licenses/by-nc-nd/4.0/'},
      ];
    }

    addLicenseDropdown(div, licenses);
  }).change();
});
