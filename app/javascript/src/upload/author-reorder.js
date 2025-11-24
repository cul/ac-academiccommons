const ready = function(){
  $( "#creator-list" ).sortable();
};

document.addEventListener('turbolinks:load', ready)
