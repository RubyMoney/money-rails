# frozen_string_literal: true

require "spec_helper"

if defined? ActiveRecord
  describe MoneyRails do
    describe "load hooks" do
      it "monetizes Active Record without a Rails initializer" do
        script = <<~RUBY
          require "money-rails"
          raise "requiring money-rails eagerly loaded Active Record" if defined?(::ActiveRecord)

          require "active_record"
          raise "monetize is missing" unless ActiveRecord::Base.respond_to?(:monetize)
        RUBY

        lib_path = File.expand_path("../../lib", __dir__)

        expect(system(RbConfig.ruby, "-I", lib_path, "-e", script)).to be(true)
      end
    end
  end
end
