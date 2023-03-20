$(document).ready(function () {

  $('form#upload input#deposit_current_student').change(function () {
    document.getElementsByClassName('student-section')[0].style.display = "none";
    if (document.getElementById('deposit_current_student').checked == true) {
      document.getElementsByClassName('student-section')[0].style.display = "block";
    }
  }).change();

});
