// Adds creator first name, last name and uni input fields.
function addCreatorField(creatorListId) {
  var div = $("<div></div>");
  div.append('<input type="text" name="deposit[creators][][first_name]" class="deposit_creators_first_name"/>')
  div.append('<input type="text" name="deposit[creators][][last_name]" class="deposit_creators_last_name"/>')
  div.append('<input type="text" name="deposit[creators][][uni]" class="deposit_creators_uni"/>')
  div.append('<span class="sort-icon"><i class="fas fa-arrows-alt" title="Sort creators" aria-hidden></i></span><span class="visually-hidden">Sort creators</span>')

  $('#' + creatorListId).append(div);
}

// Waits for a click on button with creator-list-id data attribute and then adds
// another set of creator input fields.
$(document).ready(function(){
  $("[data-creator-list-id]").click(function(e) {
    e.preventDefault()

    creatorListId = $(this).data("creator-list-id")
    textColor = $(this).data("text-color")
    addCreatorField(creatorListId)
  });
})
