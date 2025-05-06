require "aws-sdk-core"
require "open-uri"

class EssThree
  S3 = Aws::S3::Resource.new

  def self.upload(key, file)
    t0 = Time.now
    obj = S3.bucket("postcardmailer.us").object(key)
    ImageProcessor.new(file).run
    file = File.open(file.path)
    Rails.logger.info("EssThree path: #{file.path}")
    obj
      .upload_file(file, acl: "public-read")
      .tap do
        Rails.logger.info("EssThree: upload(#{key}): elapsed:#{Time.now - t0}")
      end
  end

  def self.upload_from_url(key, url)
    t0 = Time.now
    open("image.png", "wb") do |file|
      file << open(url).read
      self.upload(key, file)
    end.tap do
      Rails.logger.info(
        "EssThree: upload_from_url(#{key}, #{url}): elapsed:#{Time.now - t0}"
      )
    end
  end
end
