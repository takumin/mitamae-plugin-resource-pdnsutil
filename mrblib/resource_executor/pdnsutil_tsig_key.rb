module ::MItamae
  module Plugin
    module ResourceExecutor
      class PdnsutilTsigKey < ::MItamae::ResourceExecutor::Base
        NotExistZoneError = Class.new(StandardError)

        def apply
          if different?
            if desired['exist']
              if current['exist']
                MItamae.logger.debug "replace #{desired}"
                absent_key(desired)
                present_key(desired)
              else
                MItamae.logger.debug "generate #{desired}"
                present_key(desired)
              end
            else
              MItamae.logger.debug "delete #{desired}"
              absent_key(desired)
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
          current['exist']     = false
          current['name']      = nil
          current['algorithm'] = nil
          current['key']       = nil

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

          lines = run_command("#{@commands.join(' ')} list-tsig-keys").stdout.split("\n")

          lines.each do |line|
            ary = line.split('. ')

            name = ary[0]
            algo = ary[1]
            key  = ary[2]

            next if attributes['name'] != name

            current['exist']     = true
            current['name']      = name
            current['algorithm'] = algo
            current['key']       = key

            break
          end

          MItamae.logger.debug "current: #{current}"
        end

        def present_key(desired)
          @commands = ['pdnsutil']

          unless desired['config_name'].empty?
            @commands << '--config-name'
            @commands << desired['config_name']
          end

          unless desired['config_dir'].empty?
            @commands << '--config-dir'
            @commands << desired['config_dir']
          end

          if desired.key?('key') and !desired['key'].empty?
            @commands << 'import-tsig-key'
          else
            @commands << 'generate-tsig-key'
          end

          @commands << desired['name']
          @commands << desired['algorithm']

          if desired.key?('key') and !desired['key'].empty?
            @commands << desired['key']
          end

          run_command("#{@commands.join(' ')}")
        end

        def absent_key(desired)
          @commands = ['pdnsutil']

          unless desired['config_name'].empty?
            @commands << '--config-name'
            @commands << desired['config_name']
          end

          unless desired['config_dir'].empty?
            @commands << '--config-dir'
            @commands << desired['config_dir']
          end

          @commands << 'delete-tsig-key'
          @commands << desired['name']

          run_command("#{@commands.join(' ')}")
        end
      end
    end
  end
end
