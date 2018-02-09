module Origen

  # Module for web helpers.
  module WebLib
    module Optionable
      class OptionableDemo
        include Origen::Model
        include Origen::Optionable
      end
      
      def self.demo
        OptionableDemo.new
      end
    end
  end
end
