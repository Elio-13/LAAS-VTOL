# Contributing

Keep the repository usable by someone starting from a fresh clone on either supported platform. Make changes on a branch and open a pull request for team review.

## Working on a change

From a clone with your current work saved, update the default branch and create a topic branch:

```bash
git switch main
git pull --ff-only
git switch -c feature/describe-your-change
```

Make the change, then review the files you intend to commit:

```bash
git status --short
git diff
```

Stage only the relevant files, commit them with a descriptive message, and push your branch. Open a pull request against `main` on GitHub. Explain what changed and how you checked it.

## What belongs in Git

Commit launch scripts, source configuration, aircraft models, and documentation. Keep `.deps/`, `.runs/`, generated builds, Python environments, and machine-specific paths out of commits. Do not modify downloaded dependency clones as the way to change team configuration; add reproducible configuration to this repository instead.

When custom aircraft files are ready, use:

| Directory | Contents |
| --- | --- |
| `models/<aircraft>/` | `model.config`, SDF, meshes, and asset attribution |
| `worlds/` | Test environments referencing the aircraft |
| `params/` | Versioned ArduPilot parameter files for each aircraft/test |
| `docs/` | Aircraft properties, mappings, assumptions, and test records |

Document mass, center of gravity, inertia, joint axes/limits, motor order, thrust direction, and aerodynamic assumptions alongside each model. Preserve source and license information for externally obtained assets.

## Checks before a pull request

For documentation or launcher changes, check shell syntax and whitespace:

```bash
bash -n scripts/env.sh scripts/setup_ubuntu.sh scripts/run_gazebo.sh scripts/run_sitl.sh scripts/check_setup.sh
git diff --check
```

On a configured computer, run `bash scripts/check_setup.sh`. For changes to dependencies, aircraft physics, actuator mapping, or flight parameters, also complete the relevant flight acceptance steps in [docs/validation.md](docs/validation.md). Record which platform was actually tested; do not infer WSL validation from a native Ubuntu run.

Update the README when a setup or launch command changes. Pin intentional dependency revisions in `config/dependencies.sh`, explain why they changed, and repeat installation and flight acceptance before marking them validated.
