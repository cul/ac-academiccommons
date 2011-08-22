class UploadedFile < ActiveRecord::Base
  
  def self.save(uploaded_file, as_name)
    directory = "data/uploads"
    path = File.join(directory, as_name)
    FileUtils.mv uploaded_file.path, path
  end
  
end