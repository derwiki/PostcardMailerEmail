require "rails_helper"

RSpec.describe ImageProcessor do
  let(:file) { double("File", path: "/tmp/test.jpg") }
  let(:metadata) { "/tmp/test.jpg JPEG 100x200" }
  let(:square_metadata) { "/tmp/test.jpg JPEG 100x100" }

  before do
    allow_any_instance_of(ImageProcessor).to receive(:`).with(
      "identify /tmp/test.jpg"
    ).and_return(metadata)
    allow_any_instance_of(ImageProcessor).to receive(:puts)
  end

  describe "#initialize" do
    it "parses metadata and sets attributes" do
      processor = ImageProcessor.new(file)
      expect(processor.filename).to eq("/tmp/test.jpg")
      expect(processor.format).to eq("JPEG")
      expect(processor.dimensions).to eq({ x: 100, y: 200 })
    end
  end

  describe "#ratio" do
    it "returns the correct ratio" do
      processor = ImageProcessor.new(file)
      expect(processor.ratio).to eq(0.5)
    end
  end

  describe "#rotate?" do
    it "returns true if ratio < 1" do
      processor = ImageProcessor.new(file)
      expect(processor.rotate?).to be true
    end
    it "returns false if ratio >= 1" do
      allow_any_instance_of(ImageProcessor).to receive(:`).with(
        "identify /tmp/test.jpg"
      ).and_return("/tmp/test.jpg JPEG 200x100")
      processor = ImageProcessor.new(file)
      expect(processor.rotate?).to be false
    end
  end

  describe "#square?" do
    it "returns true if image is square" do
      allow_any_instance_of(ImageProcessor).to receive(:`).with(
        "identify /tmp/test.jpg"
      ).and_return(square_metadata)
      processor = ImageProcessor.new(file)
      expect(processor.square?).to be true
    end
    it "returns false if image is not square" do
      processor = ImageProcessor.new(file)
      expect(processor.square?).to be false
    end
  end

  describe "#rotate!" do
    it "executes rotate command if rotate? is true" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:rotate?).and_return(true)
      expect(processor).to receive(:execute).with(
        "mogrify -rotate 90 /tmp/test.jpg"
      )
      processor.rotate!
    end
    it "does not execute if rotate? is false" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:rotate?).and_return(false)
      expect(processor).not_to receive(:execute)
      processor.rotate!
    end
  end

  describe "#add_borders!" do
    it "executes border commands if square? is true" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:square?).and_return(true)
      expect(processor).to receive(:execute).with(
        "convert /tmp/test.jpg -gravity center -background white -extent 138%x100 /tmp/test.jpg.border"
      ).ordered
      expect(processor).to receive(:execute).with(
        "mv /tmp/test.jpg.border /tmp/test.jpg"
      ).ordered
      processor.add_borders!
    end
    it "does not execute if square? is false" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:square?).and_return(false)
      expect(processor).not_to receive(:execute)
      processor.add_borders!
    end
  end

  describe "#resize!" do
    it "executes resize command" do
      processor = ImageProcessor.new(file)
      expect(processor).to receive(:execute).with(
        "mogrify -resize 2048 /tmp/test.jpg"
      )
      processor.resize!
    end
  end

  describe "#run" do
    it "calls add_borders! if square? is true" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:square?).and_return(true)
      expect(processor).to receive(:add_borders!)
      expect(processor).not_to receive(:rotate!)
      processor.run
    end
    it "calls rotate! if square? is false" do
      processor = ImageProcessor.new(file)
      allow(processor).to receive(:square?).and_return(false)
      expect(processor).to receive(:rotate!)
      expect(processor).not_to receive(:add_borders!)
      processor.run
    end
  end
end
