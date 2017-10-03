module Chef
  module Steel
    module Logger

      require 'colorize'

			# Print the raw string (including escape sequences, if any).
      def raw_log(msg = '')
        puts msg
      end

      def prompt(msg = '')
        print msg
      end

      def info(msg = '')
        log(msg, :green)
      end

      def notice(msg = '')
        log(msg, :light_magenta)
      end

      def warn(msg = '')
        log(msg, :yellow)
      end

      def error(msg = '')
        log(msg, :red)
      end

      def log(msg = '', color = nil)
        puts msg.colorize(color)
      end

    end
  end
end
