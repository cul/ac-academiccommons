const ready = ()=>{
  $(document).on("ajax:success", function(event){
    $("#usage-statistics-email-flash-message").empty()
                                              .append("<div class=\"alert alert-success\">Email was sent successfully.</div>");
    //clear form somehow
  })

  $(document).on("ajax:error", function (event) {
    var data = event.detail[0];
    $("#usage-statistics-email-flash-message").empty()
                                              .append("<div class=\"alert alert-danger\">" + data + "</div>");
  });

  $('#email-modal').on('hidden.bs.modal', function (e) {
    $("#usage-statistics-email-flash-message").empty();
    $("#email-usage-statistics").trigger('reset');
  });
};

document.addEventListener('turbo:load', ready);
document.addEventListener('turbo:render', ready);