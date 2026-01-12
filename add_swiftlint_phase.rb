#!/usr/bin/env ruby
# Script to add SwiftLint Run Script Phase to Xcode project

require 'xcodeproj'

project_path = 'Wims.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Wims' }

if target.nil?
  puts "❌ Error: Could not find 'Wims' target"
  exit 1
end

# Check if SwiftLint phase already exists
existing_phase = target.shell_script_build_phases.find do |phase|
  phase.shell_script.include?('swiftlint')
end

if existing_phase
  puts "✅ SwiftLint Run Script Phase already exists!"
  exit 0
end

# Create new Run Script Phase
phase = target.new_shell_script_build_phase('SwiftLint')
phase.shell_script = <<~SCRIPT
  if which swiftlint > /dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
SCRIPT

# Move the phase to run before Compile Sources
compile_sources_phase = target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
if compile_sources_phase
  target.build_phases.move(phase, target.build_phases.index(compile_sources_phase))
end

# Save the project
project.save

puts "✅ Successfully added SwiftLint Run Script Phase to #{target.name} target!"
puts "🔨 Build the project to run SwiftLint automatically"
