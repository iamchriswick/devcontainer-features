# Handoff: `claude-code-persistent` spec

## Task for the next session

Rework the published spec for the `claude-code-persistent` Dev Container Feature into a self-contained spec the user approves, then break it into tickets.

## Status

| Step | State |
| --- | --- |
| `/hb:triage` | Done: L, fuzzy feature |
| `/hb:grill` | Done. The user confirmed the shared understanding listed below. |
| `/hb:to-spec` | Published as GitHub issue #2 on `origin`, then edited three times. **Not approved by the user.** |
| `/hb:to-tickets` | Not started |

## References

| What | Where |
| --- | --- |
| The user's design document, the source for the spec | `.specs/claude-code-persistent.md` |
| Dev Container Features reference | `.specs/dev-container-features-reference.md` |
| Existing implementation, uncommitted | `src/claude-code-persistent/` on branch `feat/claude-code-persistent` |
| Published spec, not approved | GitHub issue #2 on `origin` |
| Tracker rules | `.specs/issue-tracker.md` |
| Test prior art | `test/lla/`, `test/_global/` |
| CI workflows | `.github/workflows/test.yaml`, `.github/workflows/validate.yml` |

## User requirements for the spec

1. The spec must be self-contained. The implementation agent will not have access to the code.
2. The user's design document is the source. Its content is intended to be carried into the spec.
3. Follow the skill instructions exactly. Work from the documents and the code, not from assumptions.
4. Ask questions only through `AskUserQuestion`, and only when the documents and the code don't answer them.
5. Don't modify GitHub workflows. The work covers this Feature only.

## Confirmed by the user

1. Claude Code is always installed, in `onCreateCommand`, with Anthropic's native installer as the remote user. The install is skipped when `claude` is already present. `CCP_INSTALL` is removed from `devcontainer-feature.json`.
2. Debian-based images only.
3. Paths:
   - `/usr/local/share/devcontainers/features/claude-code-persistent/hooks`
   - `/mnt/devcontainers/features/claude-code-persistent/conf`
   - `/mnt/devcontainers/features/claude-code-persistent/tmp`
4. Options `CCP_CONFDIR`, `CCP_JSON`, `CCP_CRED` and `CCP_TMPDIR`, with persistence behavior as implemented in `updateContent.sh`. The `CCP_CRED=false` removal block is fixed so that it removes persisted credentials.
5. Version: as stamped in `devcontainer-feature.json`.
6. Tests in `test/claude-code-persistent/`, with six scenarios:
   - `defaults`
   - `ubuntu`
   - `non_root_user`
   - `confdir_off`
   - `tmpdir_on`
   - `preinstalled`
7. Out of scope: non-Debian images, and workflow changes.

## Suggested skills

1. `/hb:to-spec #2`: update the existing spec from the design document and the confirmed points above.
2. `/hb:to-tickets #2`: after the user approves the spec.
