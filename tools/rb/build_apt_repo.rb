#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "zlib"
require_relative "package_tools"

output_dir = Pathname.new(ARGV.fetch(0, "public")).expand_path
codenames = ENV.fetch("APT_CODENAMES", "stable").split
architectures = ENV.fetch("APT_ARCHITECTURES", "amd64").split
origin = ENV.fetch("APT_ORIGIN", "OrbitBits")
label = ENV.fetch("APT_LABEL", "OrbitBits Package Repository")
description = ENV.fetch("APT_DESCRIPTION", "APT repository for OrbitBits packages")

PackageTools.command!("dpkg-scanpackages")
PackageTools.command!("apt-ftparchive")

FileUtils.mkdir_p(output_dir.join("pool", "main"))
PackageTools.warn "No DEB packages found under #{output_dir}/pool" if output_dir.glob("pool/**/*.deb").empty?

codenames.each do |codename|
  architectures.each do |arch|
    FileUtils.mkdir_p(output_dir.join("dists", codename, "main", "binary-#{arch}"))
  end
end

codenames.each do |codename|
  architectures.each do |arch|
    dir = Pathname.new("dists").join(codename, "main", "binary-#{arch}")
    packages_path = output_dir.join(dir, "Packages")

    PackageTools.info "Generating APT Packages for #{codename}/#{arch}"
    packages = PackageTools.capture!(
      "dpkg-scanpackages",
      "--arch",
      arch,
      "--multiversion",
      "pool/",
      "/dev/null",
      chdir: output_dir.to_s
    )
    File.write(packages_path, packages)
    Zlib::GzipWriter.open("#{packages_path}.gz", Zlib::BEST_COMPRESSION) { |gz| gz.write(packages) }
  end

  PackageTools.info "Generating APT Release for #{codename}"
  release = PackageTools.capture!(
    "apt-ftparchive",
    "-o", "APT::FTPArchive::Release::Origin=#{origin}",
    "-o", "APT::FTPArchive::Release::Label=#{label}",
    "-o", "APT::FTPArchive::Release::Suite=#{codename}",
    "-o", "APT::FTPArchive::Release::Codename=#{codename}",
    "-o", "APT::FTPArchive::Release::Architectures=#{architectures.join(" ")}",
    "-o", "APT::FTPArchive::Release::Components=main",
    "-o", "APT::FTPArchive::Release::Description=#{description}",
    "release",
    "dists/#{codename}",
    chdir: output_dir.to_s
  )
  release_path = output_dir.join("dists", codename, "Release")
  File.write(release_path, release)

  next unless ENV.fetch("SIGN_REPO", "false") == "true"

  PackageTools.command!("gpg")
  fingerprint = ENV.fetch("GPG_FINGERPRINT") { PackageTools.abort_with "GPG_FINGERPRINT is required when SIGN_REPO=true" }
  passphrase_file = ENV.fetch("GPG_PASSPHRASE_FILE") { PackageTools.abort_with "GPG_PASSPHRASE_FILE is required when SIGN_REPO=true" }

  PackageTools.info "Signing APT Release for #{codename}"
  PackageTools.run!(
    "gpg", "--batch", "--pinentry-mode", "loopback",
    "--passphrase-file", passphrase_file,
    "--local-user", fingerprint,
    "--yes", "--clearsign",
    "-o", "dists/#{codename}/InRelease",
    "dists/#{codename}/Release",
    chdir: output_dir.to_s
  )
  PackageTools.run!(
    "gpg", "--batch", "--pinentry-mode", "loopback",
    "--passphrase-file", passphrase_file,
    "--local-user", fingerprint,
    "--yes", "-abs",
    "-o", "dists/#{codename}/Release.gpg",
    "dists/#{codename}/Release",
    chdir: output_dir.to_s
  )
end
