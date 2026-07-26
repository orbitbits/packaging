#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "find"
require "pathname"
require "time"
require "yaml"

root = Pathname.new(ARGV.fetch(0, "public")).expand_path
config = YAML.load_file("_data/generic.yml")
brand = config.fetch("brand")
packages = config.fetch("packages")

abort "Directory not found: #{root}" unless root.directory?

def human_size(bytes)
  units = [["GB", 1024**3], ["MB", 1024**2], ["KB", 1024]]
  unit = units.find { |_, threshold| bytes >= threshold }
  return "#{bytes} B" unless unit

  label, threshold = unit
  format("%.1f %s", bytes.to_f / threshold, label)
end

def html_escape(value)
  CGI.escapeHTML(value.to_s)
end

def relative_title(root, dir)
  relative = dir.relative_path_from(root).to_s
  relative == "." ? "/" : "/#{relative}/"
end

def package_directory?(root, dir)
  relative = dir.relative_path_from(root).to_s
  relative == "deb" ||
    relative.start_with?("deb/") ||
    relative == "rpm" ||
    relative.start_with?("rpm/") ||
    relative == "keys"
end

def render_index(root, dir, brand, packages)
  title = relative_title(root, dir)
  entries = dir.children.reject { |entry| entry.basename.to_s == "index.html" }
               .reject { |entry| entry.basename.to_s.start_with?(".") }
               .sort_by { |entry| [entry.directory? ? 0 : 1, entry.basename.to_s] }

  rows = []
  unless dir == root
    rows << %(<tr><td><a href="../">../</a></td><td>-</td><td>-</td></tr>)
  end

  entries.each do |entry|
    name = entry.basename.to_s
    href = entry.directory? ? "#{name}/" : name
    size = entry.directory? ? "-" : human_size(entry.size)
    date = entry.mtime.utc.strftime("%Y-%m-%d")
    label = entry.directory? ? "#{name}/" : name
    rows << format(
      '<tr><td><a href="%<href>s">%<label>s</a></td><td>%<size>s</td><td>%<date>s</td></tr>',
      href: html_escape(href),
      label: html_escape(label),
      size: html_escape(size),
      date: html_escape(date)
    )
  end

  File.write(dir.join("index.html"), <<~HTML)
    <!doctype html>
    <html lang="en-US">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Index of #{html_escape(title)} - #{html_escape(packages.fetch("title"))}</title>
      <link rel="stylesheet" href="/assets/css/style.css">
    </head>
    <body>
      <header class="site-header">
        <a class="brand" href="/">#{html_escape(brand.fetch("name"))}</a>
        <nav aria-label="Package repositories">
          <a href="/deb/">DEB</a>
          <a href="/rpm/">RPM</a>
          <a href="/keys/orbitbits.gpg">GPG key</a>
        </nav>
      </header>
      <main class="page">
        <h1>Index of #{html_escape(title)}</h1>
        <table>
          <thead>
            <tr><th>Name</th><th>Size</th><th>Date</th></tr>
          </thead>
          <tbody>
            #{rows.join("\n            ")}
          </tbody>
        </table>
      </main>
    </body>
    </html>
  HTML
end

directories = []
Find.find(root.to_s) do |path|
  dir = Pathname.new(path)
  directories << dir if dir.directory? && package_directory?(root, dir)
end

directories.sort_by { |dir| dir.to_s.count("/") }.reverse_each do |dir|
  render_index(root, dir, brand, packages)
end

puts "Generated index.html in #{directories.length} package directories"
