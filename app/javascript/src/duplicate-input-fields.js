$(document).ready(function(){
  $("[data-duplicate-fields-template]").click(function(e) {
    e.preventDefault();

    fieldsTemplateClass = $(this).data("duplicate-fields-template");
    $( "." + fieldsTemplateClass).last()
                                 .clone()
                                 .find("input:text").val("").end()
                                 .find("option:selected").removeAttr("selected").end()
                                 .insertAfter( $("." + fieldsTemplateClass).last() );
  });
})
