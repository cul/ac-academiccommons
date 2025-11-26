import Dropzone from 'dropzone';
// import * as ActiveStorage from '@rails/activestorage'; // maybe redundant?

// Overriding default file upload action provided by dropzone. Instead loading
// file via active storage and saving a signed id in a hidden element.
const ready = function() {
  Dropzone.autoDiscover = false;

  if ($('div#deposit-drop').length == 0){
    return;
  }

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
  // via https://stackoverflow.com/questions/45800079/dropzone-js-error-uncaught-typeerror-dropzone-is-not-a-function
  var myDropzone = new Dropzone("div#deposit-drop", {
    dictDefaultMessage: "<span class='link-color'>Select a file</span> or drag and drop here",
    url: directUploadUrl,
    paramName: fileVariableName,
    uploadMultiple: false, // disabling because we treat each file individually.
    hiddenInputContainer: 'div#file-upload',
    createImageThumbnails: false,
    previewTemplate: previewTemplate,
    init: function(){
      this._uploadData = function(files, dataBlocks){
        for (var i = 0; i < files.length; i++) {
          var file = files[i]
          var upload = new ActiveStorage.DirectUpload(file, this.options.url);
          var dropzone = this;

          upload.create(function (error, blob){
            if (error) {
              // Handle the error
              dropzone._errorProcessing([file], 'Error Uploading File');
            } else {
              //  Add an appropriately-named hidden input to the form with a
              //  value of blob.signed_id so that the blob ids will be
              //  transmitted in the normal upload flow
              var hiddenField = document.createElement('input');
              hiddenField.setAttribute("type", "hidden");
              hiddenField.setAttribute("value", blob.signed_id);
              hiddenField.name = dropzone.options.paramName;
              document.querySelector('form#upload').appendChild(hiddenField);
              dropzone._finished([file]);
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
  hiddenFileInputs.forEach( function(currentValue, currentIndex, listObj) { currentValue.remove(); } );
};

document.addEventListener('turbolinks:load', ready);