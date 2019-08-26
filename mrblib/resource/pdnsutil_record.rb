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

        # SOA
        define_attribute :mname, type: String
        define_attribute :rname, type: String
        define_attribute :refresh, type: Numeric
        define_attribute :retries, type: Numeric
        define_attribute :expire, type: Numeric
        define_attribute :minimum, type: Numeric

        # Other
        define_attribute :content, type: [String, Array]

        self.available_actions = [:present, :absent]
      end
    end
  end
end
