const ready = function () {
  // For contact_authors/new ERB view
  $("[data-duplicate-fields-template]").click(function (e) {
    e.preventDefault();

    const fieldsTemplateClass = $(this).data("duplicate-fields-template");
    $("." + fieldsTemplateClass)
      .last()
      .clone()
      .find("input:text")
      .val("")
      .end()
      .find("option:selected")
      .removeAttr("selected")
      .end()
      .insertAfter($("." + fieldsTemplateClass).last());
  });

  // For featured_searches/_form ERB view partial
  $("[data-featured-search-duplicate-fields-template]").click(function (e) {
    // N.B. -- when editing an existing record, this element will be inserted between the last form-group div and the corresponding hidden input
    // that will not matter, as hidden inputs are matched to their corresponding inputs by matching attribute values, not by location in the DOM.
    // When an input is submitted without a corresponding hidden input, it is treated by rails as a new record instead of an update to an existing one.
    e.preventDefault();

    const fieldsTemplateClass = $(this).data(
      "featured-search-duplicate-fields-template",
    );
    const newFormEl = $("." + fieldsTemplateClass)
      .last()
      .clone();
    const newInputEl = newFormEl.find("input:text");
    const timestamp = new Date().getTime();
    const newName = newInputEl
      .attr("name")
      .replace(/\[\d+\]/, `[${timestamp}]`);
    const newId = newInputEl.attr("id").replace(/\_\d+\_/, `[${timestamp}]`);

    newFormEl.find("input").val("");
    newFormEl.attr("for", newId);
    newInputEl.attr("name", newName);
    newInputEl.attr("id", newId);

    newFormEl.insertAfter($("." + fieldsTemplateClass).last());
  });

  $(".data-feed-search-fields-remove-button").on("click", (e) => {
    const row = e.currentTarget.closest(".row");
    row.remove();
  });

  $("#data-feed-search-fields-add-button").on("click", (e) => {
    e.preventDefault();
    const templateContent = $("#data-feed-search-fields-add-button")
      .closest("fieldset")
      .find("template")
      .html();
    const newElement = $(templateContent);
    // Each search field consists of 2 inputs (key, value). So the newest field's
    // index should be the number of indices divided by 2.
    const newIndex = $("#search-fields-inputs").find("input").length / 2;
    const newKeyId = `data_feed_search_fields_attributes_${newIndex}_key`;
    const newName = `data_feed[search_fields_attributes][${newIndex}]`;
    const newValueId = `data_feed_search_fields_attributes_${newIndex}_value`;
    const oldKeyInput = newElement.find(
      "#data_feed_search_fields_attributes_NEW_INDEX_key",
    );
    const oldValueInput = newElement.find(
      "#data_feed_search_fields_attributes_NEW_INDEX_value",
    );
    oldKeyInput.attr("id", newKeyId);
    oldKeyInput.attr("name", `${newName}[key]`);
    oldKeyInput.prev("label").attr("for", newKeyId);
    oldValueInput.attr("id", newValueId);
    oldValueInput.attr("name", `${newName}[value]`);
    oldValueInput.prev("label").attr("for", newValueId);
    $("#search-fields-inputs").append(newElement);
  });
};

document.addEventListener("turbolinks:load", ready);
document.addEventListener("turbo:load", ready);
