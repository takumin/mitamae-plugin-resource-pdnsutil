module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilMeta < ::MItamae::ResourceExecutor::Base
        NotExistZoneError = Class.new(StandardError)

        def apply
          if different?
            if desired['exist']
              if current['exist']
                MItamae.logger.debug "replace #{desired}"
                present(desired)
              else
                MItamae.logger.debug "generate #{desired}"
                present(desired)
              end
            else
              MItamae.logger.debug "delete #{desired}"
              absent(desired)
            end
          end
        end

        private

        attr_reader 'commands'

        def set_desired_attributes(desired, action)
          case action
          when :present
            desired['exist'] = true
          when :absent
            desired['exist'] = false
          else
            raise NotImplementedError
          end

          MItamae.logger.debug "desired: #{desired}"
        end

        def set_current_attributes(current, action)
          current['exist'] = false
          current['zone']  = nil
          current['kind']  = nil
          current['value'] = nil

          @commands = ['pdnsutil']

          unless attributes['config_name'].empty?
            current['config_name'] = attributes['config_name']
            @commands << '--config-name'
            @commands << attributes['config_name']
          end

          unless attributes['config_dir'].empty?
            current['config_dir'] = attributes['config_dir']
            @commands << '--config-dir'
            @commands << attributes['config_dir']
          end

          zones = run_command("#{@commands.join(' ')} list-all-zones").stdout.split("\n")

          if zones.include?(attributes['zone'])
            current['zone'] = attributes['zone']
          else
            raise NotExistZoneError, "'#{attributes['zone']}' zone does not exist."
          end

          args = ['get-meta', attributes['zone'], attributes['kind']]

          lines = run_command("#{@commands.join(' ')} #{args.join(' ')}").stdout.split("\n")

          # Metadata for 'DOMAIN NAME'
          lines.shift

          lines.each do |line|
            ary = line.split('=')

            kind  = ary[0].strip
            value = ary[1].strip

            next if kind != attributes['kind']
            next if value.empty?

            current['exist'] = true
            current['kind']  = kind
            current['value'] = value.split(', ').to_a

            break
          end

          MItamae.logger.debug "current: #{current}"
        end

        def present(desired)
          @commands = ['pdnsutil']

          unless desired['config_name'].empty?
            @commands << '--config-name'
            @commands << desired['config_name']
          end

          unless desired['config_dir'].empty?
            @commands << '--config-dir'
            @commands << desired['config_dir']
          end

          args = ['set-meta', desired['zone'], desired['kind']]

          if desired['value'].class == Array
            args << desired['value'].join(' ')
          else
            args << desired['value']
          end

          run_command("#{@commands.join(' ')} #{args.join(' ')}")
        end

        def absent(desired)
          @commands = ['pdnsutil']

          unless desired['config_name'].empty?
            @commands << '--config-name'
            @commands << desired['config_name']
          end

          unless desired['config_dir'].empty?
            @commands << '--config-dir'
            @commands << desired['config_dir']
          end

          args = ['set-meta', desired['zone'], desired['kind']]

          run_command("#{@commands.join(' ')} #{args.join(' ')}")
        end
      end
    end
  end
end
