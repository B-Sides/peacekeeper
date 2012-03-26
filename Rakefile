require 'bundler/gem_tasks'

desc 'Run all the tests'
task :test do
  sh 'bacon -a'
end

task :bump => 'bump:patch'
namespace :bump do
  require 'ripper'
  class VerParser < Ripper
    VER_REGEX = /(?<major>\d*)\.(?<minor>\d*)\.(?<patch>\d*)/

    def initialize(filename)
      super(File.read(filename), filename)
    end

    def on_const(name)
      @ver = name == 'VERSION'
    end

    def on_tstring_content(str)
      md = VER_REGEX.match(str)
      raise "Bad version string format: #{str}" unless md
      @major = md[:major]
      @minor = md[:minor]
      @patch = md[:patch]
      @line = lineno - 1
      @char = column - 1
    end

    def bump_major
      parse
      write_version("#{@major.to_i + 1}.#{@minor}.#{@patch}")
    end

    def bump_minor
      parse
      write_version("#{@major}.#{@minor.to_i + 1}.#{@patch}")
    end

    def bump_patch
      parse
      write_version("#{@major}.#{@minor}.#{@patch.to_i + 1}")
    end

    def write_version(ver)
      lines = File.read(filename).lines.to_a
      lines[@line][@char..-1] = "'#{ver}'\n"
      File.write(filename, lines.join)
    end
  end

  task :major do
    VerParser.new('./lib/peacekeeper/version.rb').bump_major
  end

  task :minor do
    VerParser.new('./lib/peacekeeper/version.rb').bump_minor
  end

  task :patch do
    VerParser.new('./lib/peacekeeper/version.rb').bump_patch
  end
end
