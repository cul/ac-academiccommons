// Disable all input elements in form
const ready = function(){
  $('form.disable :input').prop('disabled', true);
};

document.addEventListener('turbo:load', ready);