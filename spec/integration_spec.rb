require "spec_helper"

xdescribe "bundle install against gemstash" do
  let(:dir) { bundle_path(bundle) }

  after do
    clean_bundle bundle
  end

  context "with just cached gems" do
    let(:bundle) { "speaker" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir).successful?).to be_truthy
      result = execute("bundle exec speaker hi", dir: dir)
      expect(result.successful?).to be_truthy
      expect(result.output).to eq("Hello world\n")
    end
  end

  context "with just private gems" do
    it "successfully bundles"
  end

  context "with private and cached gems" do
    it "successfully bundles"
  end

  context "with private versions overriding public gems" do
    it "successfully bundles"
  end
end
