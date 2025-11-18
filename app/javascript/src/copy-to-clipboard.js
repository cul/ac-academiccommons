import ClipboardJS from "clipboard";

$(document).ready(function(){

  $('button.copy-to-clipboard').tooltip({
    trigger: 'click',
    placement: 'top'
  });

  function setTooltip(btn, message) {
    $(btn).tooltip('hide')
      .attr('data-original-title', message)
      .tooltip('show');
  }

  function hideTooltip(btn) {
    setTimeout(function() {
      $(btn).tooltip('hide');
    }, 3000);
  }

  var clipboard = new ClipboardJS('button.copy-to-clipboard');

  clipboard.on('success', function(e) {
    setTooltip(e.trigger, 'Copied!');
    hideTooltip(e.trigger);
  });

  clipboard.on('error', function(e) {
    setTooltip(e.trigger, 'Failed!');
    hideTooltip(e.trigger);
  });
});
