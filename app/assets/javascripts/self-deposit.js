
$(document).ready(function(){
  var accordion = $("#stepForm").accordion({animated: false, autoHeight: false});
  var current = 0;

  $('#start_button').click(function(){
    $('#intro').hide();
    $('#sd-form-wrap').show();
  });


  // accordion functions

  $('#sd-form-wrap').hide();

  if ($(document).getUrlParam("agreement")){
    $('#intro').hide();
    $('#sd-form-wrap').show();
    accordion.accordion("activate", 1);
    current = 1;
    $('input[name=acceptedAgreement]').attr('checked', true);
  }

  $.validator.addMethod("pageRequired", function(value, element) {
    var $element = $(element)
    function match(index) {
      return current == index && $(element).parents("#sf" + (index + 1)).length;
    }
    if (match(0) || match(1) || match(2)) {
      return !this.optional(element);
    }
    return "dependency-mismatch";
  }, $.validator.messages.required)

  var v = $("#sd-form").validate({
    errorClass: "warning",
    onkeyup: false,
    onblur: true,
    errorElement:"span",
    errorPlacement: function(error, element){
      element.parent().prepend(error);
    },
    submitHandler: function(form) {
      form.submit();
    }
  });

  // back buttons do not need to run validation
  $("#sf2 .prevbutton" ).click(function(){
    accordion.accordion("activate", 0);
    current = 0;
  });
  $( '#editlink-1').click(function(){
    accordion.accordion("activate", 1);
    current = 1;
  });
  $( '#editlink-2').click(function(){
    accordion.accordion("activate", 2);
    current = 2;
  });

  $("#sf3 .prevbutton").click(function(){
    accordion.accordion("activate", 1);
    current = 1;
  });

  // these buttons all run the validation, overridden by specific targets above
  $(".open2").click(function() {
    if (v.form()) {
      previewForm();
      accordion.accordion("activate", 2);
      current = 2;
    }
  });
  $(".open1").click(function() {
    if (v.form()) {
      accordion.accordion("activate", 1);
      current = 1;
    }
  });
  $(".open0").click(function() {
    if (v.form()) {
      accordion.accordion("activate", 0);
      current = 0;
    }
  });

  function previewForm(){
    var file = 	$('#file').val();

    var temp = new Array();
    temp = file.split('\\');

    $('#name-check').html($('#name').val());
    $('#uni-check').html($('#uni').val());
    $('#email-check').html($('#email').val());
    $('#title-check').html($('#title').val());
    $('#author-check').html($('#author').val());
    $('#file-check').html(temp[temp.length-1]);
    $('#abstract-check').html($('#abstr').val());


    $('#url').val() != '' ? $('#url-check').html($('#url').val()) :$('#url-check').parent().hide();

    $('#doi_pmcid').val() != '' ? $('#doi-check').html($('#doi_pmcid').val()).parent().show() :$('#doi-check').parent().hide();

    $('#software').val() != '' ? $('#note-check').html($('#software').val()).parent().show() :$('#note-check').parent().hide();
  }
});
