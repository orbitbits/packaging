#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "find"
require "pathname"
require "time"
require "yaml"

root = Pathname.new(ARGV.fetch(0, "public")).expand_path
pages_dir = Pathname.new(ARGV.fetch(1, "_pages"))
config = YAML.load_file("_data/generic.yml")
packages = config.fetch("packages")

abort "Directory not found: #{root}" unless root.directory?

def human_size(bytes)
  units = [["GB", 1024**3], ["MB", 1024**2], ["KB", 1024]]
  unit = units.find { |_, threshold| bytes >= threshold }
  return "#{bytes} B" unless unit

  label, threshold = unit
  format("%.1f %s", bytes.to_f / threshold, label)
end

def relative_path(root, dir)
  relative = dir.relative_path_from(root).to_s
  relative == "." ? "" : relative
end

def directory_path(root, dir)
  relative = relative_path(root, dir)
  relative.empty? ? "/" : "/#{relative}/"
end

def package_directory?(root, dir)
  relative = relative_path(root, dir)
  relative == "deb" ||
    relative.start_with?("deb/") ||
    relative == "rpm" ||
    relative.start_with?("rpm/") ||
    relative == "keys"
end

def parent_path(path)
  return nil if path == "/"

  parts = path.delete_prefix("/").delete_suffix("/").split("/")
  parts.pop
  parts.empty? ? "/" : "/#{parts.join("/")}/"
end

def page_file(pages_dir, path)
  relative = path.delete_prefix("/").delete_suffix("/")
  relative = "root" if relative.empty?
  pages_dir.join(relative, "index.html")
end

def entry_data(entry)
  name = entry.basename.to_s
  directory = entry.directory?
  {
    "name" => name,
    "label" => directory ? "#{name}/" : name,
    "href" => directory ? "#{name}/" : name,
    "size" => directory ? "-" : human_size(entry.size),
    "sort_size" => directory ? -1 : entry.size,
    "date" => entry.mtime.utc.strftime("%Y-%m-%d"),
    "sort_date" => entry.mtime.to_i
  }
end

FileUtils.rm_rf(pages_dir)
FileUtils.mkdir_p(pages_dir)

directories = []
Find.find(root.to_s) do |path|
  dir = Pathname.new(path)
  directories << dir if dir.directory? && package_directory?(root, dir)
end

directories.each do |dir|
  path = directory_path(root, dir)
  entries = dir.children.reject { |entry| entry.basename.to_s == "index.html" }
               .reject { |entry| entry.basename.to_s.start_with?(".") }
               .sort_by { |entry| [entry.directory? ? 0 : 1, entry.basename.to_s] }
               .map { |entry| entry_data(entry) }

  page = {
    "layout" => "directory",
    "title" => "Index of #{path}",
    "description" => "#{packages.fetch("title")} directory listing for #{path}",
    "permalink" => path,
    "directory_path" => path,
    "parent_path" => parent_path(path),
    "entries" => entries
  }

  target = page_file(pages_dir, path)
  FileUtils.mkdir_p(target.dirname)
  File.write(target, "#{page.to_yaml}---\n")
end

puts "Generated #{directories.length} Jekyll directory pages in #{pages_dir}"
