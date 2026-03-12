---
name: Pull Request
about: Submit changes to the codebase
title: ''
labels: ''
assignees: ''
---

## Description
<!-- Please provide a clear and concise description of the changes -->

## Type of Change
<!-- Mark the relevant option with an 'x' -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🎨 Style/UI update
- [ ] ♻️ Code refactoring
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update
- [ ] 🔧 Configuration change
- [ ] 🏗️ Infrastructure change

## Related Issues
<!-- Link to related issues, e.g., "Fixes #123" or "Closes #456" -->
Fixes #

## Changes Made
<!-- List the specific changes made in this PR -->
- Change 1
- Change 2
- Change 3

## Testing
<!-- Describe the tests you ran to verify your changes -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests pass locally
- [ ] CI/CD pipeline passes

### Test Coverage
<!-- If applicable, include test coverage statistics -->

## Screenshots (if applicable)
<!-- Add screenshots to demonstrate visual changes -->

## Checklist
<!-- Mark completed items with an 'x' -->
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Role-Based Access Control Checklist
<!-- Required for PRs that add/modify screens, routes, or API endpoints. -->
<!-- Reference: docs/ROLE_POLICY_MATRIX.md -->
- [ ] Menu visibility uses the correct `UserRole` capability (or N/A)
- [ ] Route has a `redirect:` guard in `app_router.dart` matching backend permission (or N/A)
- [ ] ViewSet/APIView has explicit `permission_classes` per the policy matrix (or N/A)
- [ ] Role authorization tests added/updated in `test_role_authorization.py` (or N/A)
- [ ] `docs/ROLE_POLICY_MATRIX.md` updated with new endpoint/route/menu entries (or N/A)

## Deployment Notes
<!-- Any special deployment considerations or database migrations needed? -->

## Additional Context
<!-- Add any other context about the PR here -->
