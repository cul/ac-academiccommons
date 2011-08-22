class UploadedFile < ActiveRecord::Base
  
  def self.save(uploaded_file, directory, as_name)
    path = File.join(directory, as_name)
    FileUtils.mkdir_p directory
    FileUtils.mv uploaded_file.path, path
  end
  
end