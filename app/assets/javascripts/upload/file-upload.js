// Overriding default file upload action provided by dropzone. Instead loading
// file via active storage and saving a signed id in a hidden element.

$(document).ready(function() {
  Dropzone.autoDiscover = false;

  // Reading in preview template, then deleting.
  var previewNode = document.querySelector("#preview-template");
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode);

  var input = document.querySelector('input[type=file]');
  var directUploadUrl = input.getAttribute('data-direct-upload-url');
  var fileVariableName = input.getAttribute('name');
  input.remove();

  // Initializing dropzone, when a file is added use activestorage to upload it.
  $("div#deposit-drop").dropzone({
    dictDefaultMessage: "<span class='link-color'>Select a file</span> or drag and drop here",
    url: directUploadUrl,
    paramName: fileVariableName,
    // uploadMultiple: true, // disabling because we treat each file individually.
    hiddenInputContainer: 'div#file-upload',
    createImageThumbnails: false,
    previewTemplate: previewTemplate,
    init: function(){
      this._uploadData = function(files, dataBlocks){
        for (var i = 0; i < files.length; i++) {
          var upload = new ActiveStorage.DirectUpload(files[i], this.options.url);
          var dropzone = this;

          upload.create(function (error, blob){
            if (error) {
              // Handle the error
              dropzone._errorProcessing([files[i]], 'Error Uploading File');
            } else {
              //  Add an appropriately-named hidden input to the form with a
              //  value of blob.signed_id so that the blob ids will be
              //  transmitted in the normal upload flow
              var hiddenField = document.createElement('input');
              hiddenField.setAttribute("type", "hidden");
              hiddenField.setAttribute("value", blob.signed_id);
              hiddenField.name = dropzone.options.paramName;
              document.querySelector('form#upload').appendChild(hiddenField);
              dropzone._finished([files[i]]);
            }
          })
        }
      };
    }
  });

  // Remove any attachments that may be presisted from previous requests.
  // We can revist this behavior when we can display this previously attached
  // documents in the UI.
  var hiddenFileInputs = document.querySelectorAll('input[name="deposit[files][]"][type="hidden"]');
  console.log(hiddenFileInputs);
  hiddenFileInputs.forEach( function(currentValue, currentIndex, listObj) { currentValue.remove(); } );
});
