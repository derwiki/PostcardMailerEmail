require "rails_helper"

describe EssThree do
  let(:key) { "test-key.jpg" }
  let(:file) { double("File", path: "/tmp/test.jpg") }
  let(:s3_resource) { double("S3Resource") }
  let(:bucket) { double("Bucket") }
  let(:object) { double("Object") }
  let(:upload_result) { double("UploadResult") }

  before do
    stub_const("EssThree::S3", s3_resource)
    allow(s3_resource).to receive(:bucket).with("postcardmailer.us").and_return(
      bucket
    )
    allow(bucket).to receive(:object).with(key).and_return(object)
    allow(ImageProcessor).to receive(:new).and_return(double(run: true))
    allow(File).to receive(:open).with(file.path).and_return(file)
    allow(object).to receive(:upload_file).with(
      file,
      acl: "public-read"
    ).and_return(upload_result)
    allow(Rails.logger).to receive(:info)
    allow(Time).to receive(:now).and_return(100, 101) # elapsed = 1
  end

  describe ".upload" do
    it "processes the image and uploads to S3" do
      result = described_class.upload(key, file)
      expect(ImageProcessor).to have_received(:new).with(file)
      expect(object).to have_received(:upload_file).with(
        file,
        acl: "public-read"
      )
      expect(result).to eq(upload_result)
    end
  end

  describe ".upload_from_url" do
    let(:url) { "http://example.com/image.jpg" }
    let(:temp_file) { double("TempFile", path: "/tmp/image.png") }
    before do
      allow(described_class).to receive(:open).with(
        "image.png",
        "wb"
      ).and_yield(temp_file)
      allow(described_class).to receive(:open).with(url).and_return(
        double(read: "image-bytes")
      )
      allow(temp_file).to receive(:<<)
      allow(described_class).to receive(:upload).with(
        key,
        temp_file
      ).and_return(:uploaded)
    end
    it "downloads the image and uploads it" do
      result = described_class.upload_from_url(key, url)
      expect(temp_file).to have_received(:<<).with("image-bytes")
      expect(described_class).to have_received(:upload).with(key, temp_file)
      expect(result).to eq(:uploaded)
    end
  end
end
