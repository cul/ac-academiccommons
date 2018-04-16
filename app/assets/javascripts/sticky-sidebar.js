$(document).ready(function(){
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#static-text #sidebar').affix({
    offset: {
      top: 300,
      bottom: navHeight
    }
  });
});
