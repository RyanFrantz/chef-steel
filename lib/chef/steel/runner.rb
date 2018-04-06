require 'chef/steel/git'
require 'chef/steel/exceptions'
require 'chef/steel/filetools'
require 'chef/steel/logger'
require 'chef/steel/version'
require 'choice'
require 'tmpdir' # Extends Dir
require 'yaml'

module Chef
  module Steel
    class Runner

      include Chef::Steel::FileTools
      include Chef::Steel::Git
      include Chef::Steel::Logger

      def initialize
        @config = config
        @clone_destination = nil # Wait until we need it...
        @file_candidates = nil # Wait until we need it...
      end

      # Validate we're in a git repo. If not, we likely don't want to do anything.
      def validate_in_repo
        unless File.exist?('.git')
          raise NotInAGitRepository, "We don't appear to be inside a Git repository!"
        end
      end

      # A hash of values describing our config.
      def config
        @config ||= {}
      end

      # An array of path names for files that are candidates for being copied.
      def file_candidates
        @file_candidates ||= []
      end

      # Create a temporary directory to clone the repo into.
      def clone_destination
        @clone_destination ||= Dir.mktmpdir('chef-steel-')
      end

      # Look for and parse steel.yml.
      # Supports a global and local config (in the repo).
      # Order matters with latter configs' definitions overriding
      # previous configs' values.
      def parse_config
        %w(/etc/steel/steel.yml steel.yml).each do |cfg|
          if File.exist?(cfg)
            begin
              y = YAML.load_file(cfg)
            rescue Psych::SyntaxError => e
              error "[#{e.class}] Failed to parse '#{cfg}'!!"
              error e.message
              exit 1
            end
            # Merge the contents of the config into @config.
            config.merge!(y)
          end
        end
      end

      # Command line options.
      def parse_options
        Choice.options do
          header ''
          header 'Hone your tools!'
          header ''
          header 'Options:'

          default_xfiles = %w(
          )

          option :exclude_files do
            short '-e'
            long  '--exclude-files *XFILES' # Yeah, XFILES!
            desc  'One or more explicit file names (space-separated) to *exclude* from being copied from the repo'
            desc  'Ex. -e README.md'
            desc  'Ex. --exclude-files README.md metadata.rb'
            desc  "Default: #{default_xfiles.to_s}"
            default default_xfiles
          end

          option :files do
            short '-f'
            long  '--files *FILES'
            desc  'One or more explicit file names (space-separated) to copy from the repo'
            desc  'Ex. -f .rubocop.yml'
            desc  'Ex. --files .rubocop.yml .rspec'
            desc  'Default: All top-level files in the repo (excluding the value of --exclude-files)'
          end

          option :repo do
            short '-r'
            long  '--repo'
            desc  'The full URL of a repo containing config files to clone'
          end

          option :version do
            short '-v'
            long  '--version'
            desc  'Show version and exit'
            action do
              puts "chef-steel v#{Chef::Steel::VERSION}"
              exit
            end
          end

          option :answer_yes do
            short '-y'
            long  '--yes'
            desc  'Answer "yes" to all prompts'
            desc  'Default: false'
            default false
          end

          footer ''
        end
        # Merge command line options on top of the config values.
        # Command line option win. Every. Time.
        config.merge!(Choice.choices)
      end

      # After we've parsed the config and command line options, let's
      # ensure the final config includes a minimal set of options.
      def validate_config
        if config['repo'].nil? || !config['repo'].is_a?(String) || config['repo'].empty?
          error "No 'repo' value found in 'steel.yml' or on the command line!"
          error "Which repo would you like to pull files from?"
          Choice.help
          exit 2
        end
      end

      # Locate potential files at the top of the directory.
      # We won't traverse into any subdirectories.
      # use Dir.glob rather than Find.find as the latter doesn't
      # provide a native way to minimize depth (like the `find` command).
      # File::FNM_DOTMATCH is handy flag that surfaces dotfiles.
      def find_top_files(clone_destination)
        globule = File.join(clone_destination, '*') # Define a variable here so the next line is legible.
        Dir.glob(globule, File::FNM_DOTMATCH).each do |path|
          next if File.directory?(path) # Should omit '.' and '..' as well.
          next if config['exclude_files'].include? File.basename(path)
          unless config['files'].nil? || config['files'].empty?
            next unless config['files'].include? File.basename(path)
          end
          file_candidates << path
        end
      end

      # Copy files from the cloned repo into this local repo.
      def copy_files
        file_candidates.each do |remote_file|
          local_file = File.basename(remote_file)
          if File.exist?(local_file)
            if same_file?(local_file, remote_file)
              info "\n>> '#{local_file}' has the same contents here as in the repo. Leaving it alone."
            else
              if config['answer_yes']
                warn "\n>> '#{local_file}' is different than its counterpart in the repo."
                info "Copying #{remote_file} to #{local_file}... (answer_yes is true)"
                copy_file(remote_file, local_file)
              else
                warn "\n>> '#{local_file}' is different than its counterpart in the repo (see below)"
                git_diff(local_file, remote_file)
                prompt "\nDo you want to overwrite #{local_file} with the version from the repo? [y/N]: "

                answer = $stdin.gets.chomp
                case answer
                when ''
                  error 'Moving on.' # Default behavior.
                when /y/i
                  info "Copying #{remote_file} to #{local_file}..."
                  copy_file(remote_file, local_file)
                when /n/i
                  error 'Moving on.'
                else
                  error 'Unknown selection. Moving on.'
                end
              end

            end
          else
            info "\n>> '#{local_file}' does not exist locally."
            info "Copying #{remote_file} to #{local_file}..."
            copy_file(remote_file, local_file)
          end
        end
      end

      def run
        validate_in_repo
        parse_config
        parse_options
        validate_config

        # Do work, son.
        repo = config['repo']
        log "\nCloning #{repo} into #{clone_destination}..."
        git_clone(repo, clone_destination)
        find_top_files(clone_destination)
        copy_files
        clean_up(clone_destination)
        info "\nAll done!"
      end

    end
  end
end
