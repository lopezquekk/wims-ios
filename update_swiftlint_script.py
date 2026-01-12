#!/usr/bin/env python3
"""
Update SwiftLint script to include Homebrew paths
"""

import re

project_file = 'Wims/Wims.xcodeproj/project.pbxproj'

# Read the project file
with open(project_file, 'r') as f:
    content = f.read()

# New shell script that includes Homebrew paths
new_script = r'''if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
else
    export PATH="/usr/local/bin:$PATH"
fi

if command -v swiftlint >/dev/null 2>&1
then
    swiftlint
else
    echo "warning: \`swiftlint\` command not found - See https://github.com/realm/SwiftLint#installation for installation instructions."
fi
'''

# Escape for pbxproj format (replace newlines with \n and escape quotes)
escaped_script = new_script.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

# Find and replace the shellScript line
pattern = r'(shellScript = )"[^"]*swiftlint[^"]*";'
replacement = f'shellScript = "{escaped_script}";'

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back
with open(project_file, 'w') as f:
    f.write(content)

print("✅ Updated SwiftLint script to include Homebrew paths")
print("🔨 Try building again in Xcode")
