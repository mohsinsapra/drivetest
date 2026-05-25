#!/usr/bin/env ruby

require 'date'
require 'fileutils'

class VersionManager
  PUBSPEC_PATH = '../pubspec.yaml'
  CHANGELOG_PATH = '../CHANGELOG.md'

  def initialize(bump_type = 'patch', changelog_entries = [])
    @bump_type = bump_type
    @changelog_entries = changelog_entries
  end

  def run
    current_version, current_build = read_current_version
    new_version, new_build = calculate_new_version(current_version, current_build)

    puts "📦 Current version: #{current_version}+#{current_build}"
    puts "🚀 New version: #{new_version}+#{new_build}"

    update_pubspec(new_version, new_build)
    update_changelog(new_version, new_build)

    puts "✅ Version updated successfully!"
    puts "📝 Don't forget to commit these changes:"
    puts "   git add pubspec.yaml CHANGELOG.md"
    puts "   git commit -m \"chore: bump version to #{new_version}+#{new_build}\""
  end

  private

  def read_current_version
    content = File.read(PUBSPEC_PATH)
    version_line = content.match(/^version:\s*(.+)\+(\d+)/)

    if version_line
      [version_line[1], version_line[2].to_i]
    else
      ['1.0.0', 1]
    end
  end

  def calculate_new_version(version, build)
    parts = version.split('.').map(&:to_i)
    major, minor, patch = parts

    case @bump_type
    when 'major'
      new_version = "#{major + 1}.0.0"
    when 'minor'
      new_version = "#{major}.#{minor + 1}.0"
    when 'patch'
      new_version = "#{major}.#{minor}.#{patch + 1}"
    when 'build'
      new_version = version
    else
      new_version = version
    end

    new_build = build + 1
    [new_version, new_build]
  end

  def update_pubspec(version, build)
    content = File.read(PUBSPEC_PATH)
    updated_content = content.gsub(/^version:\s*.+/, "version: #{version}+#{build}")
    File.write(PUBSPEC_PATH, updated_content)
  end

  def update_changelog(version, build)
    today = Date.today.to_s

    # Read current changelog
    changelog = File.read(CHANGELOG_PATH)

    # Find the unreleased section
    unreleased_section = extract_unreleased_section(changelog)

    # Fall back to last released version's content if [Unreleased] is empty
    last_released_section = unreleased_section.empty? || unreleased_section.gsub(/[#\-\s]/, '').empty? \
      ? extract_last_released_section(changelog) \
      : ""

    # Create new version entry
    new_entry = create_version_entry(version, build, today, unreleased_section, last_released_section)

    # Update changelog
    updated_changelog = changelog.sub(
      /## \[Unreleased\].*?(?=---)/m,
      "## [Unreleased]\n\n### Added\n-\n\n### Changed\n-\n\n### Fixed\n-\n\n---\n\n#{new_entry}"
    )

    File.write(CHANGELOG_PATH, updated_changelog)
  end

  def extract_unreleased_section(changelog)
    match = changelog.match(/## \[Unreleased\](.*?)---/m)
    match ? match[1].strip : ""
  end

  def extract_last_released_section(changelog)
    match = changelog.match(/## \[(?!Unreleased)[^\]]+\][^\n]*\n(.*?)---/m)
    match ? match[1].strip : ""
  end

  def create_version_entry(version, build, date, unreleased_content, last_released_content = "")
    # If there are custom changelog entries, use them
    if @changelog_entries.any?
      entries_text = format_changelog_entries(@changelog_entries)
      return "## [#{version}+#{build}] - #{date}\n\n#{entries_text}\n\n---\n"
    end

    # Use unreleased content, fall back to last released version, then generic message
    if unreleased_content.empty? || unreleased_content.gsub(/[#\-\s]/, '').empty?
      if last_released_content.empty? || last_released_content.gsub(/[#\-\s]/, '').empty?
        entries_text = "### Changed\n- Bug fixes and improvements"
      else
        entries_text = last_released_content
      end
    else
      entries_text = unreleased_content
    end

    "## [#{version}+#{build}] - #{date}\n\n#{entries_text}\n\n---\n"
  end

  def format_changelog_entries(entries)
    grouped = entries.group_by { |e| e[:type] }

    sections = []
    ['Added', 'Changed', 'Fixed', 'Removed'].each do |type|
      if grouped[type]
        sections << "### #{type}"
        grouped[type].each { |e| sections << "- #{e[:message]}" }
        sections << ""
      end
    end

    sections.join("\n")
  end
end

# Parse command line arguments
if __FILE__ == $0
  bump_type = ARGV[0] || 'patch'

  unless ['major', 'minor', 'patch', 'build'].include?(bump_type)
    puts "❌ Invalid bump type: #{bump_type}"
    puts "Usage: ruby update_version.rb [major|minor|patch|build]"
    puts ""
    puts "Examples:"
    puts "  ruby update_version.rb patch   # 1.0.0 -> 1.0.1 (default)"
    puts "  ruby update_version.rb minor   # 1.0.0 -> 1.1.0"
    puts "  ruby update_version.rb major   # 1.0.0 -> 2.0.0"
    puts "  ruby update_version.rb build   # 1.0.0+1 -> 1.0.0+2"
    exit 1
  end

  manager = VersionManager.new(bump_type)
  manager.run
end
