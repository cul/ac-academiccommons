$(document).ready(function(){
    $(".scroll").click(function(event) {
      var $target = $(this.hash);

      event.preventDefault();
      $('html').animate({
          scrollTop: $target.offset().top -20
      }, 550);
      $target.addClass('active');
  });
});
