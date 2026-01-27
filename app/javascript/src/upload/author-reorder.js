const ready = function(){
  $( "#creator-list" ).sortable();
};

document.addEventListener('turbo:load', ready)
