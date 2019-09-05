
$(document).ready(function(){
	$('.mediaelement-player video, .mediaelement-player audio').each(function() {
    $(this).mediaelementplayer({
      customError: '<p>There was an error loading this file.</p>',
    })
  });
});
