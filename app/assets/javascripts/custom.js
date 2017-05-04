// Originally this code was in application.js, but have to be moved out. This
// file eventually, should be organized better and renamed.

jQuery(document).ready(function() {

    // Replace input function
    $('.replaceInput').each(function(){

        var thisVal = $(this).attr('value');
        $(this).focus(function(){
            if($(this).attr('value')==thisVal){
                $(this).attr('value','');
            }
        }).blur(function(){
            if($(this).attr('value')==''){
                $(this).attr('value',thisVal);
            }
        });
    });


  // adds classes for zebra striping table rows
  $('table.zebra tr:even').addClass('zebra_stripe');
  $('ul.zebra li:even').addClass('zebra_stripe');


/*************
 * Facet more dialog. Uses JQuery UI Dialog. Use crazy closure technique.
 * http://docs.jquery.com/UI/Dialog
 */



    //Make sure more facet lists loaded in this dialog have
    //ajaxy behavior added to next/prev/sort
    function addBehaviorToMoreFacetDialog(dialog) {
      var dialog = $(dialog)

      // Make next/prev/sort links load ajaxy
      dialog.find("div.prev_next_links > a, a.sort_change").click( function() {
          $("body").css("cursor", "progress");
          dialog.load( this.href,
              function() {
                addBehaviorToMoreFacetDialog(dialog);
                $("body").css("cursor", "auto");
              }
          );
          //don't follow original href
          return false;
      });
    }

    function positionDialog(dialog) {
      dialog = $(dialog);

    /*   dialog.dialog("option", "height", $(window).height()-125); */
      dialog.dialog("option", "width", Math.max(  ($(window).width() /2), 45));
      dialog.dialog("option", "position", ['center', 75]);

      dialog.dialog("open").dialog("moveToTop");
    }


    $("a.more_facets_link,a.lightboxLink").each(function() {
      //We use each to let us make a Dialog object for each
      //a, tied to that a, through the miracle of closures. the second
      // arg to 'bind' is used to make sure the event handler gets it's
      // own dialog.
      var dialog_box = "empty";
      var link = $(this);
      $(this).click( function() {
        //lazy create of dialog
        if ( dialog_box == "empty") {
          dialog_box = $('<div class="dialog_box"></div>').dialog({ autoOpen: false});
        }
        // Load the original URL on the link into the dialog associated
        // with it. Rails app will give us an appropriate partial.
        // pull dialog title out of first heading in contents.
        $("body").css("cursor", "progress");
        dialog_box.load( this.href , function() {
	        if(link.attr("class") == "more_facets_link"){
            addBehaviorToMoreFacetDialog(dialog_box);
				  }
				  // Remove first header from loaded content, and make it a dialog
		      // title instead
		      var heading = dialog_box.find("h1, h2, h3, h4, h5, h6").eq(0).remove();
		      dialog_box.dialog("option", "title", heading.text());
          $("body").css("cursor", "auto");
        });

        positionDialog(dialog_box);

        return false; // do not execute default href visit
      });

    });


/* highlight breadcrumb <li> element when mouseover <a>     */
 $("a.filter").hover(function(){
     $(this).parents("li").addClass("highlight");
   },function(){
     $(this).parents("li").removeClass("highlight");
   });


  $("a.facet_deselect").hover(function(){

     $(this).parents("li").addClass("highlight");
   },function(){
     $(this).parents("li").removeClass("highlight");
   });


    $("#split_button").toggle();
   $('#hidden_search_field').attr("name","search_field");
	 $('#hidden_search_field').attr("id","search_field");
	 $("#split_button .drop_down li").each(function(){
	  $(this,$(this).children("a")).click(function(){
		  $('#search_field').attr('value',$(this).attr("class"));
		  if($(this).text() == "All Fields"){
			  $("#run").children(".ui-button-text").text("Search");
			}else{
		    $("#run").children(".ui-button-text").text("Search " + $(this).text());
	    }
		  $("#split_button .drop_down").toggle();
		/*   $("#search form").trigger("submit"); */
		  return false;
	  });
	 });


/*
 * Reloads log content for the current index running. Once the index is done
 * changes the cancel link to return to main admin indexing page.
*/
$("#ingest_monitor_content").each
  (function() {
    $(this).val("Please wait, we'll start monitoring the log file shortly...");
    var log_monitor_resource = $(this).attr("name");
    var wait = null;
    var intervalId = setInterval
    (function() {
      if(wait == true) return;
      wait = true;
      $.ajax ({
        type: "GET",
        url: log_monitor_resource,
        dataType: "json",
        processData: true,
        success: function(data) {
          $("#ingest_monitor_content").val(data.log);
          wait = false;
          if(data.log.indexOf('FINISHED') >= 0) {
            clearInterval(intervalId);
            $("#cancel_ingest_link").removeAttr("data-method");
            $("#cancel_ingest_link").html("Return to the Main Ingest Form");
          }
        },
        error: function(data, text, error){
          console.debug(text);
          console.debug(error);
          wait = false;
        }
      });
    }, 3000)
  })
});



function $$archiveDeposit(url)
{
	if(confirm("Archiving will delete the file associated with the record from the file system\n\nAre you sure you want to archive this record?"))
	{
		document.location = url
	}
}
