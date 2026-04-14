# Contributing to AWX Resource Operator

Hi there! We're excited to have you as a contributor.

Have questions about this document or anything not covered here? Please file an issue at [https://github.com/ansible/awx-resource-operator/issues](https://github.com/ansible/awx-resource-operator/issues).

## Things to know prior to submitting code

- All code submissions are done through pull requests against the `devel` branch.
- Take care to make sure no merge commits are in the submission, and use `git rebase` vs `git merge` for this reason.
- If collaborating with someone else on the same branch, consider using `--force-with-lease` instead of `--force`. This will prevent you from accidentally overwriting commits pushed by someone else. For more information, see [git push --force-with-lease](https://git-scm.com/docs/git-push#git-push---force-with-leaseltrefnamegt).
- We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions, or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com).

## Setting up your development environment

See [docs/development.md](docs/development.md) for prerequisites, build/deploy instructions, and available Makefile targets.

## Submitting your work

1. From your fork's `devel` branch, create a new branch to stage your changes.
```sh
git checkout -b <branch-name>
```
2. Make your changes.
3. Test your changes (see [Testing](#testing) below).
4. Commit your changes.
```sh
git add <FILES>
git commit -m "My message here"
```
5. Create your [pull request](https://github.com/ansible/awx-resource-operator/pulls).

## Testing

All changes must be tested before submission:

- **Linting** (required for all PRs): `make lint`
- See the [Testing section in docs/development.md](docs/development.md#testing) for details on running tests locally.

## Reporting Issues

We welcome your feedback, and encourage you to file an issue when you run into a problem at [https://github.com/ansible/awx-resource-operator/issues](https://github.com/ansible/awx-resource-operator/issues).
