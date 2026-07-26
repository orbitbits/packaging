#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "package_tools"

public_dir = Pathname.new(ARGV.fetch(0, "public"))
rpm_dir = Pathname.new(ARGV.fetch(1, "tmp-rpms"))

PackageTools.command!("rpm")
rpm_files = PackageTools.files(rpm_dir, "**/*.rpm")
PackageTools.abort_with "No RPM files found in #{rpm_dir}" if rpm_files.empty?

rpm_files.each do |rpm_file|
  arch = PackageTools.capture!("rpm", "-qp", "--queryformat", "%{ARCH}", rpm_file.to_s).strip
  target_dir = public_dir.join("rpm", arch)

  FileUtils.mkdir_p(target_dir)
  PackageTools.info "Importing #{rpm_file.basename} into #{target_dir}"
  FileUtils.cp(rpm_file, target_dir)
end
