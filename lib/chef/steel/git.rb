require 'chef/steel/logger'

module Chef
  module Steel
    module Git

      include Chef::Steel::Logger

      # Clone a repo into a given destination. We assume the destination is
      # a temporary directory.
      def git_clone(repo, destination)
        result = `git clone -q #{repo} #{destination}`
        if $?.exitstatus != 0
          error "Failed to clone #{repo} into #{destination} (Exit status: #{$?.exitstatus})!"
          error "Result: #{result}" unless result.empty?
          exit $?.exitstatus
        end
      end

      def git_diff(local_file, remote_file)
        result = `git diff --color=always #{local_file} #{remote_file}`
        log ""
        result.split("\n").each do |line|
          raw_log "\t" + line
        end
      end

    end
  end
end
