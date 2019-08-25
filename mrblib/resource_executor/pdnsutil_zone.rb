module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilZone < ::MItamae::ResourceExecutor::Base
        def apply
          if     desired.exist &&  current.exist then return
          elsif !desired.exist &&  current.exist then @commands << 'delete-zone'
          elsif  desired.exist && !current.exist then @commands << 'create-zone'
          elsif !desired.exist && !current.exist then return
          else
            raise NotImplementedError
          end

          run_command("#{@commands.join(' ')} #{attributes.zone}")
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

          if zones.include?(attributes.zone)
            current.exist = true
          else
            current.exist = false
          end
        end
      end
    end
  end
end
