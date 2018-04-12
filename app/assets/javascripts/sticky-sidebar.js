$(document).ready(function(){
  var $body   = $(document.body);
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#sidebar').affix({
        offset: {
          top: 320,
          bottom: navHeight
        }
  });

  $body.scrollspy({
  	target: '#fixed-sidebar',
  	offset: navHeight
  });
});
