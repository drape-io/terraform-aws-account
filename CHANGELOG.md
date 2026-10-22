# Changelog

## 1.0.0

First stable release.

### Breaking changes

- `default_roles`: each entry now requires `assume_role_policy`. Before, the module skipped an entry without it, including its `access_policy`, and reported no error.
- The `hashicorp/aws` provider requirement is now `>= 6.0, < 7.0` (was `~> 6.36`).

### Behavior changes

- The module ignores changes to the account email after it creates the account. Before, a change to `name`, to the context, or to `use_context_for_name` changed the email and forced Terraform to replace the account.

### Added

- The `context` variable accepts `tag_key_case` and `tag_value_case` and passes them to terraform-null-context. Before, the module dropped them.

### Fixed

- `role_arns` output description: the map is keyed by role key.
- `permission_assignments` description: users are keyed by Identity Store `UserName`, and group keys are labels.

### Documentation

- The README pins examples to `?ref=v1.0.0`, lists requirements, and adds a `users` example.
- New README section on changing or removing an account: email changes, `assume_role`, how to disable an account that has `default_roles`, and `close_on_deletion`.

### CI

- Pin GitHub Actions to commit SHAs, set `permissions: contents: read` and `persist-credentials: false`.
- Pull requests without the LocalStack token skip the test job instead of failing.
- Dependabot tracks the Compose file, waits 7 days before it proposes an update, and groups GitHub Actions updates.
