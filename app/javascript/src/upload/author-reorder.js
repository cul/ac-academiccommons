const ready = function(){
  console.log('author-reorder JS loaded!')
  $( "#creator-list" ).sortable();
};

document.addEventListener('turbolinks:load', ready)

