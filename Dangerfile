# Dangerfile for wims-ios
# Runs automated PR checks

# ========================================
# RULE 1: PR Description Required
# ========================================
if github.pr_body.length < 10
  fail("Please provide a detailed PR description. Use the PR template.")
end

# Check if PR description contains only template placeholders
template_placeholders = [
  "<!-- Briefly describe the changes made in this PR -->",
  "<!-- Mark with an 'x'",
  "<!-- List the most important changes -->"
]

if template_placeholders.any? { |placeholder| github.pr_body.include?(placeholder) }
  warn("It looks like you haven't filled out the PR template completely. Please add meaningful descriptions.")
end

# ========================================
# RULE 2: Code Size Warnings (>500 lines)
# ========================================
# Count total lines added (excluding deletions)
total_lines_added = git.lines_of_code

if total_lines_added > 500
  warn("This PR is quite large (#{total_lines_added} lines added). Consider splitting into smaller PRs for easier review.")
elsif total_lines_added > 300
  message("This PR adds #{total_lines_added} lines. Make sure it's well-tested and documented.")
end

# Per-file size check
git.modified_files.each do |file|
  # Only check Swift files
  next unless file.end_with?(".swift")

  # Get file diff stats
  diff = git.diff_for_file(file)
  next unless diff

  lines_added = diff.patch.lines.count { |line| line.start_with?("+") && !line.start_with?("+++") }

  if lines_added > 300
    warn("#{file} has #{lines_added} lines added. Consider breaking it down into smaller files.")
  end
end

# ========================================
# RULE 3: Test Coverage Check
# ========================================
# Get list of new/modified Swift source files (excluding tests)
source_files = (git.added_files + git.modified_files).select do |file|
  file.end_with?(".swift") &&
    !file.include?("Tests") &&
    !file.include?("UITests") &&
    !file.end_with?("Tests.swift") &&
    !file.end_with?("App.swift")  # Skip app entry point
end

# For each new source file, check if corresponding test file exists
source_files.each do |file|
  # Extract filename without extension
  basename = File.basename(file, ".swift")

  # Skip ViewModels and Views for now (harder to test)
  next if file.include?("/Views/")

  # Look for test files in the repository
  # Patterns: <Name>Tests.swift, <Name>Test.swift
  test_patterns = [
    "**/#{basename}Tests.swift",
    "**/#{basename}Test.swift",
    "**/*Tests.swift"  # General test file in same directory
  ]

  # Check if any test file exists
  has_test = test_patterns.any? do |pattern|
    Dir.glob(pattern).any?
  end

  unless has_test
    # For new files, require tests
    if git.added_files.include?(file)
      warn("New file `#{file}` doesn't have a corresponding test file. Please add tests.")
    else
      # For modified files, just remind
      message("Modified file `#{file}` - please ensure tests are updated if needed.")
    end
  end
end

# Check if test files were modified/added when source files changed
if !source_files.empty? && git.modified_files.none? { |f| f.include?("Tests") }
  warn("Source code changed but no test files were updated. Did you add/update tests?")
end

# ========================================
# RULE 4: No WIP Commits
# ========================================
# Check commit messages for WIP indicators
wip_patterns = [
  /\bwip\b/i,
  /\bwork in progress\b/i,
  /\bdo not merge\b/i,
  /\bfixme\b/i,
  /\btodo\b.*merge/i
]

git.commits.each do |commit|
  wip_patterns.each do |pattern|
    if commit.message.match?(pattern)
      fail("Commit '#{commit.message}' appears to be WIP. Please squash WIP commits before merging.")
      break
    end
  end
end

# Check PR title for WIP
if github.pr_title.match?(/\bwip\b/i) || github.pr_title.match?(/\bwork in progress\b/i)
  fail("PR title contains 'WIP'. Please update the title before merging.")
end

# Check for draft PRs
if github.pr_draft?
  warn("This PR is marked as a draft. Remember to mark it as ready for review before merging.")
end

# ========================================
# Additional Helpful Checks
# ========================================

# SwiftLint warnings via danger-swiftlint plugin
swiftlint.lint_files inline_mode: true

# Xcode build summary (if test results exist)
if File.exist?("build/test_output/report.junit")
  xcode_summary.report("build/test_output/report.junit")
end

# Encourage smaller PRs
if git.modified_files.count > 20
  warn("This PR modifies #{git.modified_files.count} files. Consider breaking it into smaller, focused PRs.")
end

# Check for sensitive files
sensitive_files = git.modified_files.select do |file|
  file.include?(".env") ||
    file.include?("credentials") ||
    file.include?("secrets")
end

if sensitive_files.any?
  fail("This PR modifies sensitive files: #{sensitive_files.join(', ')}. Please ensure no secrets are committed.")
end

# Encourage CLAUDE.md updates for architectural changes
architectural_files = git.modified_files.select do |file|
  file.include?("/Entities/") ||
    file.include?("/Repositories/") ||
    file.include?("Package.swift")
end

if architectural_files.any? && !git.modified_files.include?("CLAUDE.md")
  message("You modified architectural files. Consider updating CLAUDE.md if needed.")
end

# Summary message
message("Thanks for your contribution! 🎉")
