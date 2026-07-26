#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"

public_dir = Pathname.new(ARGV.fetch(0, "public"))
current_pages_dir = Pathname.new(ARGV.fetch(1, "gh-pages-current"))

FileUtils.mkdir_p(public_dir)

if current_pages_dir.directory?
  current_pages_dir.children.each do |entry|
    next if entry.basename.to_s == ".git"

    FileUtils.cp_r(entry, public_dir)
  end
end

public_dir.glob("**/.nojekyll").each { |path| FileUtils.rm_f(path) }

legacy_files = %w[
  orbitbits-packaging-pub.gpg
  orbitbits.gpg
  tildr-deb-pub.gpg
  tildr-rpm-pub.gpg
  orbitbits.list
  tildr.list
  orbitbits.repo
  tildr.repo
  keys/orbitbits-packaging-pub.gpg
  deb/orbitbits-packaging-pub.gpg
  deb/orbitbits.gpg
  deb/tildr-deb-pub.gpg
  deb/tildr.list
  rpm/orbitbits-packaging-pub.gpg
  rpm/orbitbits.gpg
  rpm/tildr-rpm-pub.gpg
  rpm/tildr.repo
]

legacy_files.each { |path| FileUtils.rm_f(public_dir.join(path)) }
FileUtils.rm_rf(public_dir.join("rpm", "fedora"))
