#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "package_tools"

output_dir = Pathname.new(ARGV.fetch(0, "public")).expand_path

PackageTools.command!("createrepo_c")
rpm_files = output_dir.glob("**/*.rpm").select(&:file?)

if rpm_files.empty?
  PackageTools.warn "No RPM packages found under #{output_dir}"
  exit 0
end

def sign_repomd(path)
  return unless ENV.fetch("SIGN_REPO", "false") == "true"

  PackageTools.command!("gpg")
  fingerprint = ENV.fetch("GPG_FINGERPRINT") { PackageTools.abort_with "GPG_FINGERPRINT is required when SIGN_REPO=true" }
  passphrase_file = ENV.fetch("GPG_PASSPHRASE_FILE") { PackageTools.abort_with "GPG_PASSPHRASE_FILE is required when SIGN_REPO=true" }

  PackageTools.run!(
    "gpg", "--batch", "--pinentry-mode", "loopback",
    "--passphrase-file", passphrase_file,
    "--local-user", fingerprint,
    "--yes", "--detach-sign", "--armor",
    path.to_s
  )
end

if ENV.fetch("SIGN_RPMS", "false") == "true"
  PackageTools.command!("rpm")
  PackageTools.command!("gpg")
  fingerprint = ENV.fetch("GPG_FINGERPRINT") { PackageTools.abort_with "GPG_FINGERPRINT is required when SIGN_RPMS=true" }
  passphrase_file = ENV.fetch("GPG_PASSPHRASE_FILE") { PackageTools.abort_with "GPG_PASSPHRASE_FILE is required when SIGN_RPMS=true" }

  File.write(
    File.join(Dir.home, ".rpmmacros"),
    <<~MACROS
      %_signature gpg
      %_gpg_name #{fingerprint}
      %_gpg_path #{File.join(Dir.home, ".gnupg")}
      %_gpgbin /usr/bin/gpg
      %__gpg_sign_cmd %{__gpg} gpg --batch --no-armor --no-tty --pinentry-mode loopback --passphrase-file #{passphrase_file} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}
    MACROS
  )

  rpm_files.each do |rpm_file|
    PackageTools.info "Signing RPM #{rpm_file.basename}"
    PackageTools.run!("rpm", "--addsign", rpm_file.to_s)
  end
end

PackageTools.info "Generating aggregate RPM metadata for #{output_dir}"
PackageTools.run!("createrepo_c", "--no-database", output_dir.to_s)
sign_repomd(output_dir.join("repodata", "repomd.xml"))

rpm_files.map(&:dirname).uniq.sort.each do |dir|
  next if dir == output_dir

  PackageTools.info "Generating RPM metadata for #{dir}"
  PackageTools.run!("createrepo_c", "--no-database", dir.to_s)
  sign_repomd(dir.join("repodata", "repomd.xml"))
end
