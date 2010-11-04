// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


$(function(){
	var bl = new Blacklight();
});

$(document).ready(function() {
  // adds classes for zebra striping table rows
  $('table.zebra tr:even').addClass('zebra_stripe');
  $('ul.zebra li:even').addClass('zebra_stripe');
 
  //add highlight to search results
  var q = $("#q");
  if(q != null && q != undefined && q != "")
  {
	  q = q.val();
	  $(".document *").each
	  (
		  function()
		  {
			  console.debug($(this));
			  if($(this).children().length == 0)
		      {
				  var re = new RegExp(q, "g");
				  console.debug($(this).text());
				  $(this).html($(this).text().replace(re, '<span class="highlight">' + q + '</span>'));
		      }
		  }
	  );
  }
  
/*************  
 * Facet more dialog. Uses JQuery UI Dialog. Use crazy closure technique. 
 * http://docs.jquery.com/UI/Dialog
 */
 
 
    
    //Make sure more facet lists loaded in this dialog have
    //ajaxy behavior added to next/prev/sort                    
    function addBehaviorToMoreFacetDialog(dialog) {
      var dialog = $(dialog)      
      
      // Make next/prev/sort links load ajaxy
      dialog.find("a.next_page, a.prev_page, a.sort_change").click( function() {     
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
      
      dialog.dialog("option", "height", $(window).height()-125);
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
    
    
 $("a.filter").hover(function(){
     $(this).parents("li").addClass("highlight");
   },function(){
     $(this).parents("li").removeClass("highlight");
   });
 
  
  
/* keep facet boxes visible after page scroll   */
var placeholder = $( "#facet-wrapper" );
var sb = $( "#facets" );
var sc = $("#hd-mini");
var view = $( window );
view.bind(
"scroll resize",
function(){

    var placeholderTop = placeholder.offset().top;

    var viewTop = view.scrollTop();

  if (
    (viewTop > placeholderTop) &&
    !sb.is( ".facets-fixed" )
  ){
 

    placeholder.height(placeholder.height());
 

    sb.addClass( "facets-fixed" );
   
   sc.addClass('visible');


} else if (
(viewTop <= placeholderTop) &&
sb.is( ".facets-fixed" )
){
 

placeholder.css( "height", "auto" );

sb.removeClass( "facets-fixed" );
sc.removeClass("visible");
 
}
}
);
 
    
    
});