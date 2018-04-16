$(document).ready(function(){
  var navHeight = $('.navbar').outerHeight(true) + 10;

  $('#sidebar-fixed').affix({
    offset: {
      top: 300,
      bottom: navHeight
    }
  });
});
