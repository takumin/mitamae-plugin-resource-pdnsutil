module ::MItamae
  module Plugin
    module Resource
      class Pdnsutil < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :name, type: String, default_name: true

        self.available_actions = [:present, :absent]
      end
    end
  end
end
