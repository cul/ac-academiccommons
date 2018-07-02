// Overriding default file upload action provided by dropzone. Instead loading
// file via active storage and saving a signed id in a hidden element.

// TODO: This needs to be revisited soon for a more elegant solution.

const uploadFile = function (file) {
  const input = document.querySelector('input[type=file]')

  // your form needs the file_field direct_upload: true, which
  // provides data-direct-upload-url
  const url = input.dataset.directUploadUrl

  const upload = new ActiveStorage.DirectUpload(file, url);

  upload.create((error, blob) => {
    if (error) {
      // Handle the error
      file.previewElement.classList.add("dz-error");
    } else {
      //  Add an appropriately-named hidden input to the form with a
      //  value of blob.signed_id so that the blob ids will be
      //  transmitted in the normal upload flow
      const hiddenField = document.createElement('input')
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("value", blob.signed_id);
      hiddenField.name = input.name
      document.querySelector('form#upload').appendChild(hiddenField)
      file.previewElement.classList.add("dz-success");
    }
  })
}

$(document).ready(function() {
  Dropzone.autoDiscover = false;

  // Reading in preview template, then deleting.
  var previewNode = document.querySelector("#preview-template");
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode);

  // Initializing dropzone, when a file is added use activestorage to upload it.
  $("div#deposit-drop").dropzone({
    init: function(){
      const input = document.querySelector('input[type=file]')
      const inputTwo = document.querySelector('input[class=dz-hidden-input]')

      inputTwo.setAttribute('data-direct-upload-url', input.getAttribute('data-direct-upload-url'));
      inputTwo.setAttribute('name', input.getAttribute('name'));
      inputTwo.setAttribute('id', input.getAttribute('id'));

      input.remove();

      this.on("addedfile", function(file) {
        uploadFile(file);
      });
    },
    dictDefaultMessage: "<span class='link-color'>Select a file</span> or drag and drop here",
    paramName: 'deposit[files][]',
    uploadMultiple: true,
    autoProcessQueue: false,
    hiddenInputContainer: 'div#file-upload',
    createImageThumbnails: false,
    previewTemplate: previewTemplate
  });

  // Remove any attachments that may be presisted from previous requests.
  // We can revist this behavior when we can display this previously attached
  // documents in the UI.
  const hiddenFileInputs = document.querySelectorAll('input[name="deposit[files][]"][type="hidden"]');
  console.log(hiddenFileInputs);
  hiddenFileInputs.forEach( function(currentValue, currentIndex, listObj) { currentValue.remove(); } )
});
