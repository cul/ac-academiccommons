
    var in_process = false;
    
	var docs_finished = false;
	var views_finished = false;
	var downloads_finished = false;
	var streams_finished = false;
    
    var facets = new Array();
    facets['authors'] = 'author_facet';
	facets['pub_dates'] = 'pub_date_facet';
	facets['genre'] = 'genre_facet';
	facets['subjects'] = 'subject_facet';
	facets['type_of_resources'] = 'type_of_resource_facet';
	facets['media_types'] = 'media_type_facet';
	facets['organizations'] = 'organization_facet';
	facets['departments'] = 'department_facet';
	facets['series'] = 'series_facet';
	facets['non_cu_series'] = 'non_cu_series_facet';

function hide_facet_results(){
	
	document.getElementById( "resut_period" ).style.visibility = 'hidden'; 
	
	document.getElementById( "search_link" ).style.visibility = 'hidden';
	document.getElementById( "statistic_res_list_link" ).style.visibility = 'hidden';
	document.getElementById( "csv_link" ).style.visibility = 'hidden';
	document.getElementById( "csv_email_link" ).style.visibility ='hidden';

	document.getElementById( "facet-docs-size" ).style.visibility = 'hidden';
    document.getElementById( "facet-views-size" ).style.visibility = 'hidden';
    document.getElementById( "facet-downloads-size" ).style.visibility = 'hidden';
    document.getElementById( "facet-streams-size" ).style.visibility = 'hidden';
}

function datepickers(){
	
	hide_facet_results();
	
	if(document.getElementById( "lifetime" ).checked == 1 ){
		document.getElementById( "date_from_div" ).style.visibility = 'hidden';
		document.getElementById( "date_to_div" ).style.visibility = 'hidden';
	} else {
		document.getElementById( "date_from_div" ).style.visibility = 'visible';
		document.getElementById( "date_to_div" ).style.visibility = 'visible';
	}

}

function get_date_params() {
    var date_params = "";
    
    date_params = date_params + "&month_from=" +  document.getElementById( 'month_from' ).value;
    date_params = date_params + "&year_from=" + document.getElementById( 'year_from' ).value;
    date_params = date_params + "&month_to=" + document.getElementById( 'month_to' ).value;
    date_params = date_params + "&year_to=" + document.getElementById( 'year_to' ).value;
    
    return date_params;
   }

function make_period_to_show() {

    var from =  document.getElementById( 'month_from' ).value + ' ' + document.getElementById( 'year_from' ).value;
    var to =  document.getElementById( 'month_to' ).value + ' ' + document.getElementById( 'year_to' ).value ;
    
    return from + " - " + to;
   }  

function get_facet_stats(){
	
	if(in_process) {
		return;
	} 
	
	in_process = true;
		
	docs_finished = false;
	views_finished = false;
	downloads_finished = false;
	streams_finished = false;

    disableOrEnableElements (facets , true);

    document.getElementById( "facet-docs-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "facet-docs-size" ).style.visibility = 'visible';
    
    document.getElementById( "facet-views-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "facet-views-size" ).style.visibility = 'visible';   
    
    document.getElementById( "facet-downloads-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "facet-downloads-size" ).style.visibility = 'visible';   
    
    document.getElementById( "facet-streams-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "facet-streams-size" ).style.visibility = 'visible';       

	var author_facet_value = document.getElementById( facets['authors'] ).value;
	var pub_date_facet_value = document.getElementById( facets['pub_dates'] ).value;
	var genre_facet_value = document.getElementById( facets['genre'] ).value;
	var subject_facet_value = document.getElementById( facets['subjects'] ).value;
	var type_of_resource_facet_value = document.getElementById( facets['type_of_resources'] ).value;
	var media_type_facet_value = document.getElementById( facets['media_types'] ).value;
	var organization_facet_value = document.getElementById( facets['organizations'] ).value;
	var department_facet_value = document.getElementById( facets['departments'] ).value;
	var series_facet_value = document.getElementById( facets['series'] ).value;
	var non_cu_series_facet_value = document.getElementById( facets['non_cu_series'] ).value;
	
	var search_params = "";
	
	if(author_facet_value) { search_params = search_params + "&f[" + facets['authors'] + "][]=" + author_facet_value;}
	if(pub_date_facet_value) { search_params = search_params + "&f[" + facets['pub_dates'] + "][]=" + pub_date_facet_value;}
	if(genre_facet_value) { search_params = search_params + "&f[" + facets['genre'] + "][]=" + genre_facet_value;}
	if(subject_facet_value) { search_params = search_params + "&f[" + facets['subjects'] + "][]=" + subject_facet_value;}
	if(type_of_resource_facet_value) { search_params = search_params + "&f[" + facets['type_of_resources'] + "][]=" + type_of_resource_facet_value; }
	if(media_type_facet_value) { search_params = search_params + "&f[" + facets['media_types'] + "][]=" + media_type_facet_value;}
	if(organization_facet_value) { search_params = search_params + "&f[" + facets['organizations'] + "][]=" + organization_facet_value;}
	if(department_facet_value) { search_params = search_params + "&f[" + facets['departments'] + "][]=" + department_facet_value;}
	if(series_facet_value) { search_params = search_params + "&f[" + facets['series'] + "][]=" + series_facet_value;}
	if(non_cu_series_facet_value) { search_params = search_params + "&f[" + facets['non_cu_series'] + "][]=" + non_cu_series_facet_value;}

	document.getElementById( "search_link" ).href = '/?' + search_params;
	
	if(document.getElementById( "lifetime" ).checked != 1 ){
		search_params = search_params + get_date_params();
		document.getElementById( "resut_period" ).innerHTML = make_period_to_show();
		document.getElementById( "resut_period" ).style.visibility = 'visible'; 
	} else {
		document.getElementById( "resut_period" ).innerHTML = 'lifetime';
		document.getElementById( "resut_period" ).style.visibility = 'visible'; 
	}
	
	document.getElementById( "statistic_res_list_link" ).href = '/statistics/statistic_res_list/?' + search_params;
	document.getElementById( "csv_link" ).href = '/statistics/common_statistics_csv/?' + search_params;
	
	
	document.getElementById( "csv_email_link" ).setAttribute('onclick','javascript:csv_email_form("' + escape(search_params) + '");');
	
	  $.ajax({url: "/statistics/docs_size_by_query_facets/?" + search_params + "",
           success: function(data) {
             $("#facet-docs-size").html(data);
	         docs_finished = true;
	         
	         if(data != 0){
	         	document.getElementById( "search_link" ).style.visibility ='visible';
	         	document.getElementById( "statistic_res_list_link" ).style.visibility ='visible';
	         	document.getElementById( "csv_link" ).style.visibility ='visible';
	         	document.getElementById( "csv_email_link" ).style.visibility ='visible';
	         }
	         
             makeFasetStatsButtonAvailable(docs_finished, views_finished, downloads_finished, streams_finished, facets);
           }
      });
  
	  $.ajax({url: "/statistics/facetStatsByEvent/?" + search_params + "&event=View",
           success: function(data) {
             $("#facet-views-size").html(data);
			 views_finished = true;
             makeFasetStatsButtonAvailable(docs_finished, views_finished, downloads_finished, streams_finished, facets);
           }
      });
      
	  $.ajax({url: "/statistics/facetStatsByEvent/?" + search_params + "&event=Download",
           success: function(data) {
             $("#facet-downloads-size").html(data);
			 downloads_finished = true;
	         makeFasetStatsButtonAvailable(docs_finished, views_finished, downloads_finished, streams_finished, facets);
           }
      });
      
	  $.ajax({url: "/statistics/facetStatsByEvent/?" + search_params + "&event=Streaming",
           success: function(data) {
             $("#facet-streams-size").html(data);
			 streams_finished = true;
			 makeFasetStatsButtonAvailable(docs_finished, views_finished, downloads_finished, streams_finished, facets);
           }
      });
      
}

function makeFasetStatsButtonAvailable(docs_finished, views_finished, downloads_finished, streams_finished, facets){

	if(docs_finished && views_finished && downloads_finished && streams_finished){
		disableOrEnableElements (facets, false);
        in_process = false;
	  }
}

function disableOrEnableElements (element_names, argument) {
  for (var name in element_names) {
	document.getElementById( element_names[name] ).disabled = argument;
  }
  
    document.getElementById( "facet-statistics-button" ).disabled = argument;
    document.getElementById( "lifetime" ).disabled = argument;
    
    document.getElementById( "month_from" ).disabled = argument;
    document.getElementById( "year_from" ).disabled = argument;
    document.getElementById( "month_to" ).disabled = argument;
    document.getElementById( "year_to" ).disabled = argument;
  
}

	var pid_docs_finished = false;
	var pid_views_finished = false;
	var pid_downloads_finished = false;
	var pid_streams_finished = false;
	
function makeSinglePidStatsButtonAvailable(pid_docs_finished, pid_views_finished, pid_downloads_finished, pid_streams_finished){

	if(pid_docs_finished && pid_views_finished && pid_downloads_finished && pid_streams_finished){

	  document.getElementById( 'pid-statistics-button' ).disabled = false;
	  document.getElementById( 'single-pid' ).disabled = false;
	}
}

function get_single_stats(){
	
	document.getElementById( 'pid-statistics-button' ).disabled = true;
	document.getElementById( 'single-pid' ).disabled = true;
	
	document.getElementById( "pid-docs-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "pid-views-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "pid-downloads-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';
    document.getElementById( "pid-streams-size" ).innerHTML = '<img id="facet-docs-size-spin" src="/assets/16px_on_transparent.gif"/>';	

  var pid = document.getElementById('single-pid').value;

  $.ajax({url: '/statistics/single_pid_count/?pid=' + pid,
           success: function(data) {
             $("#pid-docs-size").html(data);
             document.getElementById( "pid-docs-size" ).style.visibility = 'visible';
             pid_docs_finished = true;
             makeSinglePidStatsButtonAvailable(pid_docs_finished, pid_views_finished, pid_downloads_finished, pid_streams_finished);
           }
  });

  $.ajax({url: '/statistics/single_pid_stats/?event=View&pid=' + pid,
           success: function(data) {
             $("#pid-views-size").html(data);
             document.getElementById( "pid-views-size" ).style.visibility = 'visible';
             pid_views_finished = true;
             makeSinglePidStatsButtonAvailable(pid_docs_finished, pid_views_finished, pid_downloads_finished, pid_streams_finished);
           }
  });
  
  $.ajax({url: '/statistics/single_pid_stats/?event=Download&pid=' + pid,
           success: function(data) {
             $("#pid-downloads-size").html(data);
             document.getElementById( "pid-downloads-size" ).style.visibility = 'visible';
             pid_downloads_finished = true;
             makeSinglePidStatsButtonAvailable(pid_docs_finished, pid_views_finished, pid_downloads_finished, pid_streams_finished);
           }
  });  
  
  $.ajax({url: '/statistics/single_pid_stats/?event=Streaming&pid=' + pid,
           success: function(data) {
             $("#pid-streams-size").html(data);
             document.getElementById( "pid-streams-size" ).style.visibility = 'visible';
             pid_streams_finished = true;
             makeSinglePidStatsButtonAvailable(pid_docs_finished, pid_views_finished, pid_downloads_finished, pid_streams_finished);
           }
  });  
  
}


function csv_email_form(search_params) {
	
  //$.ajax({url: '/emails/get_csv_email_form?' + "search_query=" + search_params,
  $.ajax({url: '/emails/get_csv_email_form?' + unescape(search_params),
           success: function(data) {
             $("#email_box").html(data);
           }
  }); 
  
  $(function() {
	$( "#email_box" ).dialog({
		height: 360,
		width: 550,
		modal: true,
		position: 'center',
		resizable: true,
		buttons: {
			  Send: function() {
			  	
			  	var email_from = $("#email_from"),
                    email_to = $("#email_to"),
                    email_subject = $("#email_subject"),
                    email_message = $("#email_message");
			  	
			  	
			  	// var bValid = true;
			    // bValid = bValid && checkRegexp( email_to, /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i, "eg. ui@jquery.com" );

			  	
			  	var url = '/statistics/send_csv_report?';
			  	url = url + "&email_from=" + email_from.val();
			  	url = url + "&email_to=" + email_to.val();
			  	url = url + "&email_subject=" + email_subject.val();
			  	url = url + "&email_message=" + email_message.val();
			  	url = url + unescape(search_params);

			  $.ajax({url: url,
	
			  }); 
			  	
			  $( this ).dialog( "close" );
			}
		}	
		//visibility: 'visible'
	});
  });
	
	//document.getElementById( "email_form" ).style.visibility = 'visible';
}
