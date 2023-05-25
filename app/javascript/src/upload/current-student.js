$(document).ready(function () {
  // onChange only fires when radio button is selected
  $("form#upload input#deposit_current_student_true")
    .change(function () {
      document.getElementsByClassName("student-section")[0].style.display =
        "block";
    })
    .change();

  $("form#upload input#deposit_current_student_false")
    .change(function () {
      document.getElementsByClassName("student-section")[0].style.display =
        "none";
    })
    .change();

  //check if button is already selected on page render, ie after validation failure
  if ($("form#upload input#deposit_current_student_true").is(":checked")) {
    document.getElementsByClassName("student-section")[0].style.display =
      "block";
  }
});
