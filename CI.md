# CI/CD Documentation

## Overview

This project uses a comprehensive CI/CD setup with:
- **GitHub Actions** for workflow automation
- **Fastlane** for build/test/coverage tasks
- **Danger** for automated PR reviews
- **SwiftLint** for code style enforcement
- **Codecov** for coverage reporting

## Workflows

### Pull Request (`pull_request.yml`)

Runs on every PR to `main` or `develop`:

1. **SwiftLint** - Code style validation
2. **Build Packages** - Parallel build of PersistencyLayer & SwiftDataQuery
3. **Test Packages** - Run Swift package tests with coverage
4. **Build App** - Compile iOS app
5. **Unit Tests** - Run WimsTests with coverage
6. **UI Tests** - Only when PR has `run-ui-tests` label (optional)
7. **Danger** - Automated code review (only on non-draft PRs)

**Triggering UI Tests**: Add the `run-ui-tests` label to your PR.

### Main Branch (`main.yml`)

Runs on merge to `main`:
- Full CI pipeline (all tests including UI)
- Comprehensive coverage upload
- 30-day artifact retention

### Nightly (`nightly.yml`)

Scheduled daily at 2 AM UTC:
- Full test suite execution
- Creates GitHub issue on failure
- Can be triggered manually via "Run workflow" button

## Local Development

### Prerequisites

**Ruby 2.7+**: This project requires Ruby 2.7 or later for Danger and other gems.

```bash
# Check your Ruby version
ruby --version

# If you have Ruby < 2.7, install a newer version using Homebrew
brew install ruby

# Add Homebrew Ruby to your PATH (add to ~/.zshrc or ~/.bashrc)
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify Ruby version
ruby --version  # Should show 3.x or higher
```

**Install dependencies**:

```bash
# Install Homebrew dependencies
brew install swiftlint

# Install Ruby gems
bundle install
```

### Running Fastlane Locally

```bash
# Run SwiftLint
bundle exec fastlane lint

# Build app
bundle exec fastlane build_app

# Run unit tests
bundle exec fastlane test_unit

# Run all tests (including UI)
bundle exec fastlane test_app

# Generate coverage
bundle exec fastlane coverage

# Full CI pipeline
bundle exec fastlane ci

# Quick PR check (recommended before pushing)
bundle exec fastlane pr_check
```

### Testing Swift Packages

```bash
# PersistencyLayer
cd PersistencyLayer
swift test --enable-code-coverage

# SwiftDataQuery
cd SwiftDataQuery
swift test
```

## Danger Rules

Automated PR checks via Dangerfile:

1. **PR Description Required** - Must fill out PR template with meaningful content
2. **Code Size Warnings** - Warns if PR adds >500 lines total or >300 per file
3. **Test Coverage** - New files require tests; reminds to update tests for modified files
4. **No WIP Commits** - Blocks commits with WIP/FIXME/TODO in messages or PR title

## Code Coverage

Coverage reports upload to Codecov with flags:
- `unit-tests` - App unit tests
- `PersistencyLayer` - Package tests
- `full-suite` - Complete coverage from main branch

**Targets**:
- Project: 70% minimum
- New code (patches): 80% minimum

## GitHub Secrets

Required secrets in repository settings:

- `CODECOV_TOKEN` - Codecov upload token (get from codecov.io)
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### Setting up Codecov

1. Sign up at [codecov.io](https://codecov.io)
2. Link your GitHub repository
3. Copy the upload token
4. Add to GitHub: Settings → Secrets and variables → Actions → New repository secret
5. Name: `CODECOV_TOKEN`, Value: your token

## Troubleshooting

### Fastlane Issues

```bash
# Clean and reinstall gems
bundle clean --force
bundle install
```

### Xcode Version

CI uses Xcode 16.2. To match locally:
```bash
sudo xcode-select -s /Applications/Xcode_16.2.app
xcodebuild -version
```

### Coverage Not Uploading

1. Ensure `CODECOV_TOKEN` secret is set in repository settings
2. Check that tests ran successfully before coverage generation
3. Verify `build/coverage/cobertura.xml` file exists locally

### SwiftLint Failures

```bash
# Run locally to see all violations
swiftlint lint --strict

# Auto-fix some issues
swiftlint --fix

# See configuration
cat .swiftlint.yml
```

### Danger Not Running

1. Ensure PR is not in draft mode
2. Check that `GITHUB_TOKEN` is available (automatic in CI)
3. Run locally to test:
   ```bash
   export DANGER_GITHUB_API_TOKEN=<your_personal_access_token>
   bundle exec danger pr https://github.com/lopezquekk/wims-ios/pull/<number> --verbose
   ```

## Performance Tips

### Speed Up CI

- Skip UI tests during development (they add ~10 minutes)
- Only add `run-ui-tests` label when UI changes are made
- Use `bundle exec fastlane pr_check` locally before pushing

### Reduce GitHub Actions Minutes

- PR checks without UI: ~5-7 minutes
- PR checks with UI: ~15-17 minutes
- Main branch: ~20 minutes
- Nightly: ~20 minutes

Estimate: 40 PRs/month = 200-280 minutes (well within GitHub's 2,000 min/month free tier)

## Workflow Optimization

### Parallel Jobs

The PR workflow runs jobs in parallel where possible:
- Lint, Build Packages, Build App run simultaneously
- Test Packages runs after Build Packages
- Test Unit runs after Build App
- Danger can run independently

### Caching

- **Ruby gems**: Cached via `bundler-cache: true`
- **DerivedData**: Cached with project file hash key
- **Swift Package dependencies**: Implicit SPM caching

### Conditional Execution

- UI tests: Only with `run-ui-tests` label
- Danger: Skips draft PRs
- Coverage upload: Only on test success

## Adding New Tests

When adding new source files:

1. Create corresponding test file with `Tests` suffix
2. Danger will check for test coverage automatically
3. Run tests locally: `bundle exec fastlane test_unit`
4. Check coverage: `bundle exec fastlane coverage`

## Modifying CI Configuration

### Adding New Fastlane Lane

1. Edit `fastlane/Fastfile`
2. Add lane with description:
   ```ruby
   desc "Your lane description"
   lane :your_lane_name do
     # Your commands
   end
   ```
3. Test locally: `bundle exec fastlane your_lane_name`
4. Add to workflows if needed

### Adding New Danger Rule

1. Edit `Dangerfile`
2. Add rule with clear message:
   ```ruby
   if condition
     fail("Error message")  # Blocks merge
     warn("Warning message")  # Just warns
     message("Info message")  # FYI
   end
   ```
3. Test locally with real PR

### Modifying SwiftLint Rules

1. Edit `.swiftlint.yml`
2. Run locally: `swiftlint lint`
3. Fix violations or adjust rules
4. Commit changes

## Best Practices

### Before Creating PR

```bash
# Run quick checks
bundle exec fastlane pr_check

# Or individual steps
bundle exec fastlane lint
bundle exec fastlane test_unit
```

### During PR Review

- Address Danger comments promptly
- Fix SwiftLint violations (don't disable rules without team discussion)
- Add tests for new code
- Keep PRs focused and under 500 lines when possible

### After PR Merge

- Check main branch CI passes
- Verify coverage didn't drop significantly
- Monitor Codecov dashboard

## Resources

- [Fastlane Documentation](https://docs.fastlane.tools)
- [Danger Documentation](https://danger.systems/ruby/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.com)
