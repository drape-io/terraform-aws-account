# Changelog

## 1.0.0

First stable release.

### Breaking changes

- `default_roles`: each entry now requires `assume_role_policy`. Before, the module skipped an entry without it, including its `access_policy`, and reported no error.
- The `hashicorp/aws` provider requirement is now `>= 6.0, < 7.0` (was `~> 6.36`).
- terraform-null-context is now pinned to `v1.0.0` (was a commit on its main branch). That release adds validation: the `group`, `tenant`, `env`, `scope` and `attributes` fields of `context` can only contain letters, digits and hyphens. A context with other characters now fails at plan.

### Behavior changes

- The module ignores changes to the account email after it creates the account. Before, a change to `name`, to the context, or to `use_context_for_name` changed the email and forced Terraform to replace the account.
- Tags from terraform-null-context `v1.0.0` can change when the `context` carries `tags`:
  - The tags that the module generates (`group`, `tenant`, `environment`, `scope`) now win over a `context.tags` entry with the same key. Before, the `context.tags` value won.
  - An uppercase `env` shorthand such as `PRD` now gives `environment = production`.
  - Terraform updates these tags in place on the account and the IAM roles and policies. It does not replace them.
- Account names, emails, IAM role and policy names, and tags for a context without `tags` do not change. The tests pin these values.
- terraform-null-context no longer uses the `hashicorp/random` provider. This module never truncated its ID, so no state changes.

### Added

- The `context` variable accepts `tag_key_case` and `tag_value_case` and passes them to terraform-null-context. Before, the module dropped them.

### Fixed

- `role_arns` output description: the map is keyed by role key.
- `permission_assignments` description: users are keyed by Identity Store `UserName`, and group keys are labels.

### Documentation

- The README pins examples to `?ref=v1.0.0`, lists requirements, and adds a `users` example.
- New README section on changing or removing an account: email changes, `assume_role`, how to remove an account that has `default_roles`, and `close_on_deletion`.

### Known issues

- `enabled = false` in the context fails at plan with `Invalid index`. The module configures a provider for the new account, and that configuration needs the account. The README describes how to remove an account instead.

### CI

- Pin GitHub Actions to commit SHAs, set `permissions: contents: read` and `persist-credentials: false`.
- When the LocalStack token is not available, the test job skips the tests with a warning instead of failing.
- Dependabot tracks the Compose file, waits 7 days before it proposes an update, and groups GitHub Actions updates.
