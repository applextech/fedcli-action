# FedCLI GitHub Action

FedCLI is an AI-assisted universal database CLI for 20+ relational and non-relational engines. Alongside SQL-oriented workflows, it supports federated queries, scripting, export/import, and automation. This Docker-based GitHub Action brings the FedCLI command surface to a Linux GitHub Actions runner for repeatable CI/CD work.

Use it to:

- verify connectivity, metadata, or data-quality preconditions before a release;
- run a reviewed, version-controlled FedCLI or SQL operational script;
- automate import/export and other proven database runbooks; and
- execute a proven federated workflow across configured sources.

FedCLI returns a failed workflow step when it reports an execution error. For interactive use, supported database coverage, automation, federated queries, and AI-assisted workflows, see the [FedCLI documentation](https://applextech.com/docs/), [supported databases](https://applextech.com/docs/supported-databases/), [automation](https://applextech.com/docs/automation/), [federated queries](https://applextech.com/docs/federated-queries/), and [AI-assisted SQL](https://applextech.com/docs/ai-assisted-sql/).

It is intentionally kept as a repository-root-ready bundle. To publish it in GitHub Marketplace, place these files at the root of one dedicated public GitHub repository; do not publish the full FedCLI source repository as the Marketplace Action repository.

## What It Runs

The Action builds a small wrapper image from the public FedCLI `1.0.4` GitHub Container Registry image pinned to its verified digest:

```text
ghcr.io/ronwarshawsky/fedcli@sha256:d63a4ef714b0653bf20e0c9aa9d8e6df2c979397e3a52024ee098ba12ce2484d
```

The wrapper:

- accepts exactly one of `sql` or `script`;
- optionally creates a `CONNECT` command from `connection-url`;
- forces `WHENEVER SQLERROR EXIT FAILURE` so SQL errors fail the workflow step;
- accepts script paths only beneath the checked-out workspace; and
- never prints the supplied connection URL itself.

## Inputs

| Input | Required | Description |
| --- | --- | --- |
| `connection-url` | No | Database URL. Supply it from a GitHub Secret, such as `${{ secrets.FEDCLI_CONNECTION_URL }}`. |
| `sql` | One of `sql` or `script` | One FedCLI command or semicolon-delimited SQL command sequence. |
| `script` | One of `sql` or `script` | Checked-in FedCLI or SQL script path relative to `working-directory`. |
| `working-directory` | No | Directory beneath `GITHUB_WORKSPACE` containing the script; defaults to `.`. |

## Usage

### Run a database health check

```yaml
name: Run FedCLI check

on:
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ronwarshawsky/fedcli-action@v1
        with:
          connection-url: ${{ secrets.FEDCLI_CONNECTION_URL }}
          sql: SELECT 1;
```

### Run a checked-in FedCLI or SQL script

```yaml
name: Run FedCLI script

on:
  workflow_dispatch:

jobs:
  script:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ronwarshawsky/fedcli-action@v1
        with:
          connection-url: ${{ secrets.FEDCLI_CONNECTION_URL }}
          script: ops/check.sql
```

## Security and Runner Requirements

- Docker container Actions require a Linux runner with Docker. For private databases, use a self-hosted Linux runner that has the required network route; GitHub-hosted runners cannot normally reach private networks.
- Do not run this Action with production database secrets on workflows triggered by untrusted pull requests, forks, or user-controlled input.
- Use GitHub Secrets for `connection-url`. Never place database credentials directly in a workflow, repository file, Action metadata, Docker image, or logs.
- The invoking workflow owns the database permissions. Use an account constrained to the exact read/write access required for the script.
- The Action does not create, manage, or expose a FedCLI commercial license. If a commercial license is required, mount it through the runner's approved secret mechanism and set `FEDCLI_LICENSE_PATH` in the runtime environment.

## Marketplace Publication Checklist

1. Create a dedicated public GitHub repository, for example `ronwarshawsky/fedcli-action`.
2. Copy the contents of this directory to that repository root, retaining exactly one root `action.yml`.
3. Run the local Docker validation below and a real workflow on a non-production target.
4. Accept the GitHub Marketplace Developer Agreement for the publishing account.
5. Create a versioned release tag such as `v1.0.0`; select **Publish this Action to the GitHub Marketplace** during the GitHub release flow.
6. Choose an accurate category and publish only after the repository README, security guidance, and Action metadata are complete.

GitHub Marketplace Actions are published from public repositories and require a single root Action metadata file. A GitHub Release alone does not create a Marketplace listing.

## Local Validation

From this directory's parent repository:

```powershell
docker build -t fedcli-github-action:test integrations/github-action
docker run --rm -e INPUT_SQL="SHOW LICENSE" fedcli-github-action:test
```

The test runs the actual wrapper and FedCLI image without a database connection. A real workflow test should use an approved non-production database URL stored as a GitHub Secret.

## Subsequent Releases

The included `Release Action` workflow validates the pinned image reference, documentation, Docker wrapper, and real non-connecting FedCLI invocation for an existing `vX.Y.Z` tag. Start it with **Actions → Release Action → Run workflow**, supplying the tag. It creates the matching GitHub release and updates the stable major reference, such as `v1`, through the GitHub API. Keeping the initial Marketplace release as a draft until its Marketplace checkbox is selected avoids an accidental release outside that required interactive flow.

The FedCLI base image remains digest-pinned deliberately. Do not automatically replace it with an unreviewed `latest` image. For a new FedCLI release, update the immutable public GHCR image reference in both `Dockerfile` and this README, run `./scripts/verify-package.sh`, validate against a non-production database, then tag the Action release. This preserves the supply-chain boundary while automating repeatable release validation and release/tag publication.
