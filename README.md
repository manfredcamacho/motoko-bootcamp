# Motoko Bootcamp

Hey there! This is where I'm going to be keeping track of my progress and the results of the Motoko Bootcamp that I'm currently participating in.

# What is the Motoko Bootcamp?

[The Motoko Bootcamp](https://github.com/motoko-bootcamp) is an awesome program that helps you learn Motoko, get started on the Internet Computer, and meet other builders - all in one week! It's a recurring event that happens every three months, and it's available online so you can join from anywhere in the world.

## Prerequisites

- ### Check versions of installed tools:

  ```
  node --version # v18.13.0
  npm --version  # 9.5.*
  dfx --version  # 0.14.0
  ```

- ### dfx install

  `sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"`

- ### Create identity

  `dfx identity new <your_identity_alias>`

- ### Activate newly created identity

  `dfx identity use <your_identity_alias>`

## Install

`npm install`

## Check canister locally

```
dfx start --clean --background
dfx deploy day1
```

You can change the name of the canister, for example:

`dfx deploy day2`

## Testing

For running specs, on a terminal:

`npm run test:day1`

`npm run test:day2`

...

`npm run test` (for running all specs)
