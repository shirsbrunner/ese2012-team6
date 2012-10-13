module Storage

  class PictureUploader
    attr_accessor :root_path

    def initialize
      self.root_path = ""
    end

    def self.with_path(path)
      uploader = PictureUploader.new
      uploader.root_path = path
      return uploader
    end

    def upload(file, filename)
      if file != nil
        full_path = File.join("public", self.root_path)
        FileUtils.mkdir_p(full_path)
        FileUtils::cp(file[:tempfile].path, File.join(full_path, filename))
        return File.join(self.root_path, filename)
      else
        return "/images/no_image.gif"
      end
    end
  end
end