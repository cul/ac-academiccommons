// This enables users to navigate to a page's main content using a 'skip to main content' link. This added functionality is necessary because some browsers do not fully support in-page links. While they may visually shift focus to the location of the target or named anchor for the 'skip' link, they do not actually set keyboard focus to this location.

$( document ).ready(function() {
  $(".skip-link").click(function(event){

    var skipTo="#"+this.href.split('#')[1];

    $(skipTo).attr('tabindex', -1).on('blur focusout', function () {

        $(this).removeAttr('tabindex');

    }).focus();
  });
});
