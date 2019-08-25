module ::MItamae
  module Plugin
    module Resource
      class PdnsutilRecord < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :config_name, type: String
        define_attribute :config_dir, type: String
        define_attribute :zone, type: String, default_name: true
        define_attribute :name, type: String, required: true
        define_attribute :type, type: String, required: true
        define_attribute :ttl, type: Numeric
        define_attribute :content, type: [String, Array, Hash], required: true

        self.available_actions = [:present, :absent]
      end
    end
  end
end
