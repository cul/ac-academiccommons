function show_log(time_id, log_folder) {
	

  $.ajax({url: '/logs/log_form?log_id=' + unescape(time_id) + '&log_folder=' + unescape(log_folder),
           success: function(data) {
             $("#log_box").html(data);
             $("#log_box") .dialog('option', 'title', time_id + '.log');
           }
  }); 
  
  $(function() {
	$( "#log_box" ).dialog({
		height: 700,
		width: 900,
		modal: true,
		position: 'center',
		resizable: true,
		buttons: {
			  Close: function() {
				$( this ).dialog( "close" );
			  },
			  Download: function() {

               location = '/download/download_log/' + time_id + '?log_folder=' + log_folder;
	  	
			   $( this ).dialog( "close" );
			}
		}	
	});
  });
	
	
}