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
    e.preventDefault();
    const fieldsTemplateClass = $(this).data("featured-search-duplicate-fields-template");
    const timestamp = new Date().getTime();
    console.log($('.'+ fieldsTemplateClass).last());

    // create new element
    const new_form_el = $( "." + fieldsTemplateClass).last().clone();
    console.log('top')
    console.log(new_form_el)
    new_form_el.find("input").val("");
    // N.B. -- when editing an existing record, this element will be insrted between the last form-group div and the corresponding hidden input
    // that will not matter, as hidden inputs are matched to their corresponding inputs by matching attribute values, not by location in the DOM.
    // When an input is submitted without a corresponding hidden input, it is treated by rails as a new record instead of an update to an existing one.
    // todo : need to change the hidden input (stores fsv ID) as well when cloning!
    // update name and ID attributes of input element & for attr of container
    const new_input_el = new_form_el.find("input:text");
    const newName = new_input_el.attr("name").replace(/\[\d+\]/, `[${timestamp}]`);
    new_input_el.attr("name", newName);
    const newId = new_input_el.attr("id").replace(/\_\d+\_/, `[${timestamp}]`);
    new_input_el.attr("id", newId);
    new_form_el.attr("for", newId);
    console.log('creating new el with name '+ newName + ' and id ' + newId)
    //  todo : replace label element as well: .attr("for", newId)

    console.log ( new_form_el)
    const input_el = new_form_el.find("input:text");
    console.log ( input_el )
    const current_name = input_el.attr("name") // currently name of cloned element...  
    console.log('current name is ' + current_name) // sanity check
    new_form_el.insertAfter( $("." + fieldsTemplateClass).last() );
  });
};

document.addEventListener('turbolinks:load', ready);

        // <div class="form-group">
        //   <%= value_form.label :value, 'Filter Value' %>
        //   Delete Filter "<%= value_form.object.value %>": <%= value_form.check_box :_destroy %>
        // </div>
