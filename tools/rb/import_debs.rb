#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "package_tools"

public_dir = Pathname.new(ARGV.fetch(0, "public"))
deb_dir = Pathname.new(ARGV.fetch(1, "tmp-debs"))

PackageTools.command!("dpkg-deb")
deb_files = PackageTools.files(deb_dir, "**/*.deb")
PackageTools.abort_with "No DEB files found in #{deb_dir}" if deb_files.empty?

deb_files.each do |deb_file|
  package = PackageTools.capture!("dpkg-deb", "--field", deb_file.to_s, "Package").strip
  first_letter = package[0]
  target_dir = public_dir.join("deb", "pool", "main", first_letter, package)

  FileUtils.mkdir_p(target_dir)
  PackageTools.info "Importing #{deb_file.basename} into #{target_dir}"
  FileUtils.cp(deb_file, target_dir)
end
