
$(document).ready(function(){
  MediaElementPlayer.prototype.buildbranding = function(player, controls, layers, media) {
    // create the branding button, with Academic Commons logo and link back out to the Academic Commons item page.

    var branding =
    $('<div class="' + player.options.classPrefix + 'branding-button" style="width: 200px; cursor:pointer; position: relative;>' +
    '<button type="button" title="Columbia Academic Commons" aria-label="Columbia Academic Commons" tabindex="0"><img src="/assets/logo-media-player-badge.png" alt="" style="bottom: 9px; height: auto; max-width: 100%; position: absolute; width: 100%;"></button></div>')
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
