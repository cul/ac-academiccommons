const ready = function(){
  // For contact_authors/new ERB view
  $("[data-duplicate-fields-template]").click(function(e) {
    e.preventDefault();

    const fieldsTemplateClass = $(this).data("duplicate-fields-template");
    $( "." + fieldsTemplateClass).last()
                                 .clone()
                                 .find("input:text").val("").end()
                                 .find("option:selected").removeAttr("selected").end()
                                 .insertAfter( $("." + fieldsTemplateClass).last() );
  });

  // For featured_searches/_form ERB view partial
  $("[data-featured-search-duplicate-fields-template]").click(function(e) {
    // N.B. -- when editing an existing record, this element will be inserted between the last form-group div and the corresponding hidden input
    // that will not matter, as hidden inputs are matched to their corresponding inputs by matching attribute values, not by location in the DOM.
    // When an input is submitted without a corresponding hidden input, it is treated by rails as a new record instead of an update to an existing one.
    e.preventDefault();

    const fieldsTemplateClass = $(this).data("featured-search-duplicate-fields-template");
    const new_form_el = $( "." + fieldsTemplateClass).last().clone();
    const new_input_el = new_form_el.find("input:text");
    const timestamp = new Date().getTime();
    const newName = new_input_el.attr("name").replace(/\[\d+\]/, `[${timestamp}]`);
    const newId = new_input_el.attr("id").replace(/\_\d+\_/, `[${timestamp}]`);

    new_form_el.find("input").val("");
    new_form_el.attr("for", newId);
    new_input_el.attr("name", newName);
    new_input_el.attr("id", newId);

    new_form_el.insertAfter( $("." + fieldsTemplateClass).last() );
  });
};

document.addEventListener('turbolinks:load', ready);
document.addEventListener('turbo:load', ready);
