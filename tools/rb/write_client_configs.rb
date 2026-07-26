#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"

output_dir = Pathname.new(ARGV.fetch(0, "public"))
apt_url = ENV.fetch("APT_URL", "https://packages.orbitbits.com/deb")
rpm_url = ENV.fetch("RPM_URL", "https://packages.orbitbits.com/rpm")
key_url = ENV.fetch("KEY_URL", "https://packages.orbitbits.com/keys/orbitbits.gpg")

deb_dir = output_dir.join("deb")
rpm_dir = output_dir.join("rpm")

FileUtils.mkdir_p([deb_dir, rpm_dir])

File.write(
  deb_dir.join("orbitbits.list"),
  "deb [signed-by=/usr/share/keyrings/orbitbits.gpg] #{apt_url} stable main\n"
)

File.write(
  rpm_dir.join("orbitbits.repo"),
  <<~REPO
    [orbitbits]
    name=OrbitBits Package Repository
    baseurl=#{rpm_url}/$basearch
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=#{key_url}
  REPO
)
