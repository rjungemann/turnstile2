require 'rubygems/specification'

class Jeweler
  # Extend a Gem::Specification instance with this module to give it Jeweler
  # super-cow powers.
  #
  # [files] a Rake::FileList of anything that is in git and not gitignored. You can include/exclude this default set, or override it entirely
  # [test_files] Similar to gem.files, except it's only things under the spec, test, or examples directory.
  # [extra_rdoc_files] a Rake::FileList including files like README*, ChangeLog*, and LICENSE*
  # [executables] uses anything found in the bin/ directory.
  module Specification

    def self.filelist_attribute(name)
      code = %{
        def #{name}
          if @#{name} && @#{name}.class != FileList
            @#{name} = FileList[@#{name}]
          end
          @#{name} ||= FileList[]
        end
        def #{name}=(value)
          @#{name} = FileList[value]
        end
      }

      module_eval code, __FILE__, __LINE__ - 9
    end

    filelist_attribute :files
    filelist_attribute :test_files
    filelist_attribute :extra_rdoc_files

    # Assigns the Jeweler defaults to the Gem::Specification
    def set_jeweler_defaults(base_dir, git_base_dir = nil)
      base_dir = File.expand_path(base_dir)
      #breakpoint
      git_base_dir = if git_base_dir
                       File.expand_path(git_base_dir)
                     else
                       base_dir
                     end
      can_git = git_base_dir && base_dir.include?(git_base_dir) && File.directory?(File.join(git_base_dir, '.git'))

      Dir.chdir(git_base_dir) do
        if can_git
          require 'git'
          repo = Git.open(git_base_dir) if can_git
        end

        if blank?(files) && repo
          base_dir_with_trailing_separator = File.join(base_dir, "")

          self.files = (repo.ls_files(base_dir).keys - repo.lib.ignored_files).map do |file|
            #breakpoint
            File.expand_path(file).sub(base_dir_with_trailing_separator, "")
          end
        end

        if blank?(test_files) && repo
          self.test_files = FileList['{spec,test,examples}/**/*.rb'] - repo.lib.ignored_files
        end

        if blank?(executables)
          self.executables = Dir['bin/*'].map { |f| File.basename(f) }
        end

        if blank?(extensions)
          self.extensions = FileList['ext/**/extconf.rb']
        end

        self.has_rdoc = true
        rdoc_options << '--charset=UTF-8'

        if blank?(extra_rdoc_files)
          self.extra_rdoc_files = FileList['README*', 'ChangeLog*', 'LICENSE*', 'TODO']
        end
      end
    end

    # Used by Specification#to_ruby to generate a ruby-respresentation of a Gem::Specification
    def ruby_code(obj)
      case obj
      when Rake::FileList then obj.uniq.to_a.inspect
      else super
      end
    end

    private

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end
