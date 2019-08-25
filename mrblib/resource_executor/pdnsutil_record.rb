module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilRecord < ::MItamae::ResourceExecutor::Base
        NotExistZoneError = Class.new(StandardError)

        def apply
        end

        private

        attr_reader :commands

        def set_desired_attributes(desired, action)
          case action
          when :present
            desired.exist = true
          when :absent
            desired.exist = false
          else
            raise NotImplementedError
          end

          MItamae.logger.debug "#{desired}"
        end

        def set_current_attributes(current, action)
          @commands = ['pdnsutil']

          unless attributes.config_name.empty?
            @commands << '--config-name'
            @commands << attributes.config_name
          end

          unless attributes.config_dir.empty?
            @commands << '--config-dir'
            @commands << attributes.config_dir
          end

          zones = run_command("#{@commands.join(' ')} list-all-zones").stdout.split("\n")

          unless zones.include?(attributes.zone)
            raise NotExistZoneError, "'#{attributes.zone}' zone does not exist."
          end

          results = run_command("#{@commands.join(' ')} list-zone #{attributes.zone}").stdout.split("\n")

          name = attributes.name == '.' ? attributes.zone : attributes.name + '.' + attributes.zone
          type = attributes.type

          results.each do |result|
            case result
            when /\A(#{Regexp.escape(name)})\s+(\d+)\s+IN\s+(#{type})\s+(.*)\z/
              current.name = $1
              current.ttl  = $2
              current.type = $3

              if type == 'SOA'
              else
                current.content = $3
              end
            else
              current.exist = false
              current.name  = nil
              current.ttl   = nil
              current.type  = nil

              if type == 'SOA'
              else
                current.content = nil
              end
            end
          end
        end
      end
    end
  end
end
