$(document).ready(function(){
    $(".scroll").click(function(event) {
      var $target = $(this.hash);

      event.preventDefault();
      $('html').animate({
          scrollTop: $target.offset().top
      }, 500);
      $target.addClass('active');
  });
});
