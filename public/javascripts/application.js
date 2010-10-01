// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


$(function(){
	var bl = new Blacklight();
});

$(document).ready(function() {
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
    
    
    /* set height of #page element based on #main */
    
  $('#page').height(function(){return $('#main').height()+100+'px'; } );
  
  
// Get a reference to the placeholder. This element
// will take up visual space when the message is
// moved into a fixed position.
var placeholder = $( "#sidebar-wrapper" );
 
// Get a reference to the message whose position
// we want to "fix" on window-scroll.
var sb = $( "#sidebar" );
 
// Get a reference to the window object; we will use
// this several time, so cache the jQuery wrapper.
var view = $( window );
 
 
// Bind to the window scroll and resize events.
// Remember, resizing can also change the scroll
// of the page.
view.bind(
"scroll resize",
function(){
// Get the current offset of the placeholder.
// Since the message might be in fixed
// position, it is the plcaeholder that will
// give us reliable offsets.
var placeholderTop = placeholder.offset().top;
 
// Get the current scroll of the window.
var viewTop = view.scrollTop();
 
// Check to see if the view had scroll down
// past the top of the placeholder AND that
// the message is not yet fixed.
if (
(viewTop > placeholderTop) &&
!sb.is( ".sidebar-fixed" )
){
 
// The message needs to be fixed. Before
// we change its positon, we need to re-
// adjust the placeholder height to keep
// the same space as the message.
//
// NOTE: All we're doing here is going
// from auto height to explicit height.
placeholder.height(
placeholder.height()
);
 
// Make the message fixed.
sb.addClass( "sidebar-fixed" );

 
 
// Check to see if the view has scroll back up
// above the message AND that the message is
// currently fixed.
} else if (
(viewTop <= placeholderTop) &&
sb.is( ".sidebar-fixed" )
){
 
// Make the placeholder height auto again.
placeholder.css( "height", "auto" );
 
// Remove the fixed position class on the
// message. This will pop it back into its
// static position.
sb.removeClass( "sidebar-fixed" );
 
}
}
);
 
    
    
});



