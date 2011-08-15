$(document).ready(function() {

jQuery.validator.messages.required = "";
	$('#sd-form').validate({
		invalidHandler: function(e, validator) {
			var errors = validator.numberOfInvalids();
			if (errors) {
				var message = errors == 1
					? 'You missed 1 field. It has been highlighted below'
					: 'You missed ' + errors + ' fields.  They have been highlighted below';
				$("div.error span").html(message);
				$("div.error").show();
			} else {
				$("div.error").hide();
			}
		},
		onkeyup: false,
		submitHandler: function() {
			$("div.error").hide();
			alert("submit! use link below to go to the other step");
		},
		messages: {
			password2: {
				required: " ",
				equalTo: "Please enter the same password as above"	
			},
			email: {
				required: " ",
				email: "Please enter a valid email address, example: you@yourdomain.com" )	
			}
		},
		debug:true,
 
   success: function(label) {
     label.addClass("valid").text("Ok!");
 
   },
   submitHandler: function() { alert("Submitted!") }
}
	
	
	
	
	);



 var myOpen=function(hash){   hash.w.show(); $('#intro').remove();   }; 
 var myClose=function(hash) { hash.w.fadeOut('2000',function(){ hash.o.remove();$('#form-part-one').show(); }); };   

$('#ARA').jqm( {
ajax: 'AC2_Author_Rights_Agreement.htm', 
trigger: '#start_button', 
modal:true,  
target:$('#agreement_text'),
onShow:myOpen,
onHide:myClose




} );

});