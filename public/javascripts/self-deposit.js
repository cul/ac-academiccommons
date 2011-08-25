$(document).ready(function(){
$.fn.replaceholder();

$('#start_button').click(function(){

$('#intro').hide();
$('#sd-form-wrap').show();



});

 $("#optional-fields").hide();

$('#optionalFields').click(function(){

  if ($("#optionalFields").is(":checked"))
        {
            //show the hidden div
            $("#optional-fields").show("fast");
        }
        else
        {      
            //otherwise, hide it 
            $("#optional-fields").hide("fast");
        }

});


	// add * to required field labels
	$('label.required').append('&nbsp;<strong>*</strong>&nbsp;');

	// accordion functions
 	var accordion = $("#stepForm").accordion({animated:false, autoHeight: false}); 
	
	$('#sd-form-wrap').hide();
	var current = 0;
	
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
	    element.next().append(error);
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
	$("#sf4 .prevbutton").click(function(){
		accordion.accordion("activate", 2);
		current = 2;
	}); 
	
	$("#sf5 .prevbutton").click(function(){
		accordion.accordion("activate", 3);
		current = 3;
	}); 
	// these buttons all run the validation, overridden by specific targets above
		$(".open4").click(function() {
	  if (v.form()) {  
	accordion.accordion("activate", 4);
	current = 4;
	}
	});
	
		$(".open3").click(function() {
	  if (v.form()) {
	  
	    accordion.accordion("activate", 3);
	    current = 3;
	  }
	});
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
