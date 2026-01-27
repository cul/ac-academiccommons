const ready = function(){
  // No ordering applied by DataTables during initialisation
  // Enable horizontal scrolling
  $('.datatables').DataTable({
    "order": [],
    "scrollX": true
  });
};

document.addEventListener('turbo:load', ready);