$(document).ready(function(){
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#static-text #sidebar').affix({
    offset: {
      top: 270,
      bottom: navHeight
    }
  });
});
