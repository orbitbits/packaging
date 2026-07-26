#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"

output_dir = Pathname.new(ARGV.fetch(0, "public"))

FileUtils.mkdir_p([output_dir.join("deb"), output_dir.join("rpm")])

system("ruby", "tools/rb/build_apt_repo.rb", output_dir.join("deb").to_s, exception: true)
system("ruby", "tools/rb/build_rpm_repo.rb", output_dir.join("rpm").to_s, exception: true)
system("ruby", "tools/rb/write_client_configs.rb", output_dir.to_s, exception: true)
