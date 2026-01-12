#!/usr/bin/env python3
"""
Script to add SwiftLint Run Script Phase to Xcode project
"""

import uuid
import re

project_file = 'Wims.xcodeproj/project.pbxproj'

# Read the project file
with open(project_file, 'r') as f:
    content = f.read()

# Check if SwiftLint already exists
if 'swiftlint' in content.lower():
    print("✅ SwiftLint Run Script Phase already exists!")
    exit(0)

# Generate unique ID for the new build phase
shell_script_id = uuid.uuid4().hex[:24].upper()

# Create the shell script build phase
swiftlint_phase = f'''		{shell_script_id} /* SwiftLint */ = {{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = SwiftLint;
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "if which swiftlint > /dev/null; then\\n  swiftlint\\nelse\\n  echo \\"warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint\\"\\nfi\\n";
		}};
'''

# Find the PBXShellScriptBuildPhase section and add our phase
sources_section_pattern = r'(/\* Begin PBXSourcesBuildPhase section \*/)'
shell_section_exists = '/* Begin PBXShellScriptBuildPhase section */' in content

if shell_section_exists:
    # Add to existing section
    pattern = r'(/\* Begin PBXShellScriptBuildPhase section \*/\n)'
    content = re.sub(pattern, r'\1' + swiftlint_phase, content)
else:
    # Create new section before PBXSourcesBuildPhase
    new_section = f'''/* Begin PBXShellScriptBuildPhase section */
{swiftlint_phase}/* End PBXShellScriptBuildPhase section */

'''
    content = re.sub(sources_section_pattern, new_section + r'\1', content)

# Add the phase to the Wims target's buildPhases array (before Sources)
# Find the Wims target buildPhases
target_pattern = r'(C35A68D52F037A9F00447267 /\* Wims \*/ = \{[^}]*buildPhases = \(\s*)(C35A68D22F037A9F00447267 /\* Sources \*/)'
replacement = r'\g<1>' + shell_script_id + ' /* SwiftLint */,\n\t\t\t\t' + r'\g<2>'
content = re.sub(target_pattern, replacement, content, flags=re.DOTALL)

# Write the modified content back
with open(project_file, 'w') as f:
    f.write(content)

print("✅ Successfully added SwiftLint Run Script Phase to Wims target!")
print("🔨 Build the project to run SwiftLint automatically")
print("\nTo verify in Xcode:")
print("  1. Open Wims.xcodeproj")
print("  2. Select the Wims target")
print("  3. Go to Build Phases tab")
print("  4. You should see 'SwiftLint' phase before 'Sources'")
