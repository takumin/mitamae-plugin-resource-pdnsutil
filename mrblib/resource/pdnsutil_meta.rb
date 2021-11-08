module ::MItamae
  module Plugin
    module Resource
      class PdnsutilMeta < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :config_name, type: String
        define_attribute :config_dir, type: String
        define_attribute :zone, type: String, required: true
        define_attribute :kind, type: String, required: true
        define_attribute :value, type: [String, Array]

        self.available_actions = [:present, :absent]
      end
    end
  end
end
