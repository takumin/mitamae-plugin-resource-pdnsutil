module ::MItamae
  module Plugin
    module Resource
      class PdnsutilZone < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :config_name, type: String
        define_attribute :config_dir, type: String
        define_attribute :zone, type: String, default_name: true

        self.available_actions = [:present, :absent]
      end
    end
  end
end
