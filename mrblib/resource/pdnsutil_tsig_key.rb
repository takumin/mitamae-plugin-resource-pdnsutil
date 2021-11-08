module ::MItamae
  module Plugin
    module Resource
      class PdnsutilTsigKey < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :config_name, type: String
        define_attribute :config_dir, type: String
        define_attribute :name, type: String, default_name: true
        define_attribute :algorithm, type: String, required: true
        define_attribute :key, type: String

        self.available_actions = [:present, :absent]
      end
    end
  end
end
