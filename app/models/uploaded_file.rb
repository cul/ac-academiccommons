class UploadedFile < ApplicationRecord
  # Saves file in directory given. If there is already a file by the same name
  # present in the directory, appends numbers to the filename.
  #
  # @param uploaded_file
  # @param [String] directory
  # @param [String] original_filename
  # @return filepath where file was stored at
  def self.save(uploaded_file, directory, original_filename)
    filename = original_filename

    i = 1
    while File.exist?(File.join(directory, filename))
      extension = File.extname(original_filename)
      filename = "#{File.basename(original_filename, extension)}-#{i}#{extension}"
      i += 1
    end

    path = File.join(directory, filename)
    FileUtils.mkdir_p directory
    FileUtils.mv uploaded_file.path, path
    FileUtils.chmod 0755, path
    path
  end
end
