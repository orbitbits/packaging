# frozen_string_literal: true

require "fileutils"
require "open3"
require "pathname"
require "shellwords"

module PackageTools
  module_function

  def info(message)
    puts "\e[0;36m-> #{message}\e[0m"
  end

  def warn(message)
    puts "\e[0;33m! #{message}\e[0m"
  end

  def abort_with(message)
    warn = "\e[0;31mx #{message}\e[0m"
    abort warn
  end

  def command!(name)
    found = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
      path = File.join(dir, name)
      File.file?(path) && File.executable?(path)
    end
    return if found

    abort_with "#{name} not found"
  end

  def run!(*args, chdir: nil)
    info args.shelljoin
    system(*args, chdir: chdir, exception: true)
  end

  def capture!(*args, chdir: nil)
    stdout, stderr, status = Open3.capture3(*args, chdir: chdir)
    return stdout if status.success?

    abort_with "#{args.shelljoin} failed\n#{stderr}"
  end

  def files(root, pattern)
    Pathname.new(root).glob(pattern).select(&:file?).sort
  end
end
