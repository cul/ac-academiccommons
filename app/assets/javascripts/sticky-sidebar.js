$(document).ready(function(){
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#main-page #sidebar').affix({
    offset: {
      top: 270,
      bottom: navHeight
    }
  });
});
