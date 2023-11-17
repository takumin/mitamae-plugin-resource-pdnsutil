module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilRecord < ::MItamae::ResourceExecutor::Base
        NotExistZoneError = Class.new(StandardError)

        def apply
          if different?
            if desired.exist
              if current.exist
                replace = Hashie::Mash.new

                current.each do |k, current_value|
                  if !current_value.nil?
                    replace[k] = current_value

                    if !desired[k].nil?
                      replace[k] = desired[k]
                    end
                  end
                end

                MItamae.logger.debug "rep #{replace}"
                present_record('replace-rrset', replace)
              else
                MItamae.logger.debug "add #{desired}"
                present_record('add-record', desired)
              end
            else
              MItamae.logger.debug "del #{desired}"
              absent_record(desired)
            end
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

          case desired.name
          when NilClass, '', '.', desired.zone
            desired.name = desired.zone
          else
            desired.name = "#{desired.name}.#{desired.zone}"
          end

          case desired.type
          when 'SOA'
            if desired.key?(:mname) and !desired.mname.match(/\.\z/)
              desired.mname << '.'
            end

            if desired.key?(:rname) and !desired.rname.match(/\.\z/)
              desired.rname << '.'
            end
          when 'SRV'
            if desired.key?(:target) and !desired.target.match(/\.\z/)
              desired.target << '.'
            end
          when 'A', 'AAAA', 'PTR'
            # nothing...
          else
            desired.contents.each_with_index do |v, i|
              unless v.match(/\.\z/)
                desired.contents[i] << '.'
              end
            end
          end

          MItamae.logger.debug "desired #{desired}"
        end

        def set_current_attributes(current, action)
          current.exist = false
          current.name  = nil
          current.ttl   = nil
          current.type  = nil

          case attributes.type
          when 'SOA'
            current.mname   = nil
            current.rname   = nil
            current.serial  = nil
            current.refresh = nil
            current.retries = nil
            current.expire  = nil
            current.minimum = nil
          when 'SRV'
            current.priority = nil
            current.weight   = nil
            current.port     = nil
            current.target   = nil
          else
            current.contents = nil
          end

          @commands = ['pdnsutil']

          unless desired.config_name.empty?
            current.config_name = desired.config_name
            @commands << '--config-name'
            @commands << desired.config_name
          end

          unless desired.config_dir.empty?
            current.config_dir = desired.config_dir
            @commands << '--config-dir'
            @commands << desired.config_dir
          end

          zones = run_command("#{@commands.join(' ')} list-all-zones").stdout.split("\n")

          if zones.include?(desired.zone)
            current.zone = desired.zone
          else
            raise NotExistZoneError, "'#{desired.zone}' zone does not exist."
          end

          results = run_command("#{@commands.join(' ')} list-zone '#{desired.zone}'").stdout.split("\n")

          records = results.map do |r|
            v = r.split("\t")
            if v[0] == desired.name and v[3] == desired.type
              Hashie::Mash.new({
                :name    => v[0],
                :ttl     => v[1],
                :type    => v[3],
                :content => v[4],
              })
            else
              nil
            end
          end

          records.compact.each do |r|
            current.exist = true
            current.name  = r.name
            current.ttl   = r.ttl
            current.type  = r.type

            case r.type
            when 'SOA'
              content = r.content.split(' ')

              current.mname   = content[0].to_s.strip
              current.rname   = content[1].to_s.strip
              current.serial  = content[2].to_i
              current.refresh = content[3].to_i
              current.retries = content[4].to_i
              current.expire  = content[5].to_i
              current.minimum = content[6].to_i

              current.mname << '.' unless current.mname.match(/\.\z/)
              current.rname << '.' unless current.rname.match(/\.\z/)
            when 'SRV'
              content = r.content.split(' ')

              priority = content[0].to_i
              weight   = content[1].to_i
              port     = content[2].to_i
              target   = content[3].to_s.strip

              target << '.' unless target.match(/\.\z/)

              next if target != desired.target

              current.priority = priority
              current.weight   = weight
              current.port     = port
              current.target   = target
            else
              current.contents ||= []
              current.contents << r.content
            end
          end

          MItamae.logger.debug "current #{current}"
        end

        def present_record(command, desired)
          raise unless command.match(/^(?:add-record|replace-rrset)$/)

          commands = [command]
          commands << "'#{desired.zone}'"
          commands << "'#{desired.name.gsub(/\.?#{Regexp.escape(desired.zone)}/, '')}.'"
          commands << "#{desired.type}"

          if desired.key?(:ttl) and desired.ttl.is_a?(Numeric) and desired.ttl > 0
            commands << "#{desired.ttl}"
          end

          case desired.type
          when 'SOA'
            content = []
            content << desired.mname
            content << desired.rname
            content << desired.serial
            content << desired.refresh
            content << desired.retries
            content << desired.expire
            content << desired.minimum
            commands << "'#{content.join(' ')}'"
          when 'SRV'
            content = []
            content << desired.priority
            content << desired.weight
            content << desired.port
            content << desired.target
            commands << "'#{content.join(' ')}'"
          else
            desired.contents.each do |v|
              commands << "'#{v}'"
            end
          end

          run_command("#{@commands.join(' ')} #{commands.join(' ')}")
          run_command("#{@commands.join(' ')} increase-serial '#{desired.zone}.'")
        end

        def absent_record(desired)
          MItamae.logger.debug "delete_record #{desired}"
        end
      end
    end
  end
end
