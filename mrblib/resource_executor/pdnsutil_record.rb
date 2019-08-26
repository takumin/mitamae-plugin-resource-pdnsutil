module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilRecord < ::MItamae::ResourceExecutor::Base
        NotExistZoneError = Class.new(StandardError)

        def apply
          if    desired.exist  &&  current.exist
            desired.each do |k, v|
              next if k == :config_dir
              next if k == :config_name

              if current.key?(k)
                if current[k] != v
                  MItamae.logger.debug "k:#{k} v:#{v}"
                end
              end
            end
          elsif !desired.exist &&  current.exist
            delete_record(desired)
          elsif desired.exist  && !current.exist
            create_record(desired)
          elsif !desired.exist && !current.exist
            # nothing...
          end
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

          unless attributes.name.nil?
            unless attributes.name.match(/\.\z/)
              desired.name = attributes.name
            else
              desired.name = attributes.zone
            end
          else
            desired.name = attributes.zone
          end

          if attributes.type == 'SOA'
            unless attributes.rname.match(/\.\z/)
              desired.rname = "#{attributes.rname}.#{attributes.zone}"
            end

            unless attributes.mname.match(/\.\z/)
              desired.mname = "#{attributes.mname}.#{attributes.zone}"
            end
          end
        end

        def set_current_attributes(current, action)
          @commands = ['pdnsutil']

          unless desired.config_name.empty?
            @commands << '--config-name'
            @commands << desired.config_name
          end

          unless desired.config_dir.empty?
            @commands << '--config-dir'
            @commands << desired.config_dir
          end

          zones = run_command("#{@commands.join(' ')} list-all-zones").stdout.split("\n")

          unless zones.include?(desired.zone)
            raise NotExistZoneError, "'#{desired.zone}' zone does not exist."
          end

          results = run_command("#{@commands.join(' ')} list-zone #{desired.zone}").stdout.split("\n")

          results.each do |result|
            case result
            when /\A(#{Regexp.escape(desired.name)})\s+(\d+)\s+IN\s+(#{desired.type})\s+(.*)\z/
              current.exist = true
              current.name  = $1
              current.ttl   = $2
              current.type  = $3

              if desired.type == 'SOA'
                content         = $4.split(' ')
                current.mname   = content[0]
                current.rname   = content[1]
                current.serial  = content[2].to_i
                current.refresh = content[3].to_i
                current.retries = content[4].to_i
                current.expire  = content[5].to_i
                current.minimum = content[6].to_i
              else
                current.content = $3
              end
            else
              current.exist = false
              current.name  = nil
              current.ttl   = nil
              current.type  = nil

              if desired.type == 'SOA'
                current.mname   = nil
                current.rname   = nil
                current.serial  = nil
                current.refresh = nil
                current.retries = nil
                current.expire  = nil
                current.minimum = nil
              else
                current.content = nil
              end
            end
          end
        end

        def create_record(desired)
          # add-record ZONE NAME TYPE [ttl] content

          @commands << 'add-record'
          @commands << "'#{desired.zone}.'"
          @commands << "'#{desired.name}.'"
          @commands << "#{desired.type}"

          if desired.key?(:ttl) and desired.ttl.is_a?(Numeric) and desired.ttl > 0
            @commands << "#{desired.ttl}"
          end

          if desired.type == 'SOA'
          else
            @commands << "#{desired.content}"
          end

          MItamae.logger.debug "create_record #{@commands.join(' ')}"
        end

        def delete_record(desired)
          MItamae.logger.debug "delete_record #{desired}"
        end

        def replace_record(current, desired)
          MItamae.logger.debug "#{desired}"
          MItamae.logger.debug "#{current}"
        end
      end
    end
  end
end
