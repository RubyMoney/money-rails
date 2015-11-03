require "spec_helper"
require "securerandom"

describe Gemstash::Storage do
  before do
    @folder = Dir.mktmpdir
  end
  after do
    FileUtils.remove_entry(@folder) if File.exist?(@folder)
  end

  it "builds with a valid folder" do
    expect(Gemstash::Storage.new(@folder)).not_to be_nil
  end

  it "builds the path if it does not exists" do
    new_path = File.join(@folder, "other-path")
    expect(Dir.exist?(new_path)).to be_falsy
    Gemstash::Storage.new(new_path)
    expect(Dir.exist?(new_path)).to be_truthy
  end

  context "with a valid storage" do
    let(:storage) { Gemstash::Storage.new(@folder) }

    it "can create a child storage from itself" do
      storage.for("gems")
      expect(Dir.exist?(File.join(@folder, "gems"))).to be_truthy
    end

    it "returns a non existing resource when requested" do
      resource = storage.resource("an_id")
      expect(resource).not_to be_nil
      expect(resource).not_to exist
    end

    it "returns empty properties when they are not saved" do
      resource = storage.resource("something")
      resource = resource.save("some content").load
      expect(resource.properties).to eq({})
    end

    context "with a simple resource" do
      let(:resource) { storage.resource("an_id") }

      it "can be saved" do
        resource.save("content")
        expect(resource).to exist
      end

      it "can be read afterwards" do
        resource.save("some content")
        expect(resource.content).to eq("some content")
      end

      it "can also save properties" do
        resource.save("some other content", "content-type" => "octet/stream")
        expect(resource.content).to eq("some other content")
        expect(resource.properties).to eq("content-type" => "octet/stream")
      end

      it "can save nested properties" do
        resource.save("some other content", headers: { "content-type" => "octet/stream" })
        expect(resource.content).to eq("some other content")
        expect(resource.properties).to eq(headers: { "content-type" => "octet/stream" })
      end
    end

    context "with a previously stored resource" do
      let(:resource_id) { SecureRandom.uuid }
      let(:content) { SecureRandom.base64 }
      before do
        storage.resource(resource_id).save(content)
      end

      it "loads the content from disk" do
        resource = storage.resource(resource_id)
        resource.load
        expect(resource.content).to eq(content)
      end

      it "can have properties updated" do
        resource = storage.resource(resource_id)
        resource.update_properties(key: "value", other: :value)
        expect(storage.resource(resource_id).load.properties).to eq(key: "value", other: :value)
        resource = storage.resource(resource_id)
        resource.update_properties(key: "new", new: 42)
        expect(storage.resource(resource_id).load.properties).to eq(key: "new", other: :value, new: 42)
      end

      it "can be deleted" do
        resource = storage.resource(resource_id)
        resource.delete
        expect(resource.exist?).to be_falsey
        expect { resource.load }.to raise_error(/no content to load/)
        # Fetching the resource again will still prevent access
        resource = storage.resource(resource_id)
        expect(resource.exist?).to be_falsey
        expect { resource.load }.to raise_error(/no content to load/)
      end
    end

    context "with resource name that is unique by case only" do
      let(:first_resource_id) { "SomeResource" }
      let(:second_resource_id) { "someresource" }

      it "stores the content separately" do
        storage.resource(first_resource_id).save("first content")
        storage.resource(second_resource_id).save("second content")
        expect(storage.resource(first_resource_id).load.content).to eq("first content")
        expect(storage.resource(second_resource_id).load.content).to eq("second content")
      end

      it "uses different downcased paths to avoid issues with case insensitive file systems" do
        first_resource = storage.resource(first_resource_id)
        second_resource = storage.resource(second_resource_id)
        expect(first_resource.folder.downcase).to_not eq(second_resource.folder.downcase)
      end
    end

    context "with resource name that includes odd characters" do
      let(:resource_id) { ".=$&resource" }

      it "stores and retrieves the data" do
        storage.resource(resource_id).save("odd name content")
        expect(storage.resource(resource_id).load.content).to eq("odd name content")
      end

      it "doesn't include the odd characters in the path" do
        expect(storage.resource(resource_id).folder).to_not match(/[.=$&]/)
      end
    end
  end
end
