require 'chef/steel/logger'
require 'digest'

module Chef
  module Steel
    module FileTools

      include Chef::Steel::Logger

      # Compare two files' digests to determine if they're the same file.
      # Returns true/false based on the comparison of digest strings.
      def same_file?(local_file, remote_file)
        local_digest = Digest::SHA256.file(local_file).hexdigest
        remote_digest = Digest::SHA256.file(remote_file).hexdigest
        local_digest == remote_digest
      end

      # Copy a file from its source to its destination.
      def copy_file(src, dst)
        FileUtils.cp(src, dst)
      end

      # Remove the temporary directory using a naive guard to ensure we're
      # deleting what we expect.
      def clean_up(tmp_dir)
        info "\nCleaning up temporary directory '#{tmp_dir}"
        re_tmp_dir = Regexp.new('chef-steel')
        FileUtils.rm_rf(tmp_dir) if tmp_dir.match(re_tmp_dir)
      end

    end
  end
end
