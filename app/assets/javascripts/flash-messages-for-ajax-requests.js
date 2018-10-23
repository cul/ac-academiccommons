$(document).ready(function(){
  $(".ajax-flash-messages").on("ajax:success", function(event){
    var data = event.detail[0]['message'];
    $("#main-flashes > .flash_messages").empty()
                                        .append("<div class=\"alert alert-success\">" + data + "<a class=\"close\" data-dismiss=\"alert\" href=\"#\">×</a></div>");
    $(window).scrollTop(0);
    //clear form somehow
  }).on("ajax:error", function (event) {
    var data = event.detail[0]['message'];
    $("#main-flashes > .flash_messages").empty()
                                        .append("<div class=\"alert alert-danger\">" + data + "<a class=\"close\" data-dismiss=\"alert\" href=\"#\">×</a></div>");
    $(window).scrollTop(0);
  });
});
