$(document).ready(function(){
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#sidebar').affix({
    offset: {
      top: 300,
      bottom: navHeight
    }
  });
});
