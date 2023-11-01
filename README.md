# DeInsur [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/0xdevant/DeInsur/actions
[gha-badge]: https://github.com/PaulRBerg/foundry-template/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

DeInsur is a Foundry-based project which allows authorized admin to set up different kinds of insurance plans and the
respective price rate to determine an appropriate price for each policy. Users will then be able to purchase those
policies with their desired expiry date and insured amount, and claim automatically in ETH in case an unfortunate
incident does happen.

## Getting Started

```zsh
$ pnpm install # install all necessary packages
```

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Test

Run the tests:

```sh
$ forge test
```

Generate test coverage and output result to the terminal:

```sh
$ pnpm test:coverage
```

## License

This project is licensed under MIT.
