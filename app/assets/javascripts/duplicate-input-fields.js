$(document).ready(function(){
  $("[data-duplicate-fields-template]").click(function(e) {
    e.preventDefault()

    fieldsTemplateClass = $(this).data("duplicate-fields-template")
    clonedTemplate = $( "." + fieldsTemplateClass).last().clone()
    clonedTemplate.insertAfter( $("." + fieldsTemplateClass).last() );
  });
})
