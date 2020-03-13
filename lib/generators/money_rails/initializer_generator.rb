module MoneyRails
  module Generators
    class InitializerGenerator < ::Rails::Generators::Base

      source_root File.expand_path("../../templates", __FILE__)

      desc 'Creates a sample MoneyRails initializer.'

      def copy_initializer
        copy_file 'money.rb', 'config/initializers/money.rb'
      end

    end
  end
end
