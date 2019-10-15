
$(document).ready(function(){
  MediaElementPlayer.prototype.buildbranding = function(player, controls, layers, media) {
    // create the branding button, with Academic Commons logo and link back out to the Academic Commons item page.

    var branding =
    $('<div class="' + player.options.classPrefix + 'branding-button" title="Columbia Academic Commons">' +
    '<span>Columbia Academic Commons</span></div>')
    // append it to the toolbar
    .appendTo(controls)
    // add a click toggle event
    .click(function() {
      if (player.node.dataset.brandLink) {
        window.open(player.node.dataset.brandLink, '_blank')
      }
    });
  }

  $('.mediaelement-player video, .mediaelement-player audio').each(function() {
    $(this).mediaelementplayer({
      customError: '<p>There was an error loading this file.</p>',
      features: ['playpause', 'current', 'progress', 'duration', 'tracks', 'volume', 'fullscreen', 'branding'],
      stretching: 'responsive'
    })
  });
});
