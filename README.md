# @kin-sdk/react-native

React Native Kin SDK wrapper for the official Android and iOS Kin SDK's

## Installation

```sh
npm install @kin-sdk/react-native
```

## Usage

```ts
import { KinEnvironment, KinSdk } from '@kin-sdk/react-native';

// Set up the environment
const env = KinEnvironment.Test;

// Create a key pair
const { secret, publicKey } = KinSdk.generateRandomKeyPair();

// Create the account
const [res, err1] = await KinSdk.createNewAccount(env, { secret });

if (err1) {
  // handle error 1
}

// Resolve token accounts (contain balance)
const [accounts, err2] = await KinSdk.resolveTokenAccounts(env, { publicKey });

if (err2) {
  // handle error 2
}

// Request an airdrop
await KinSdk.requestAirdrop(env, { amount: '5000', publicKey });

// Submit a payment
const destination = 'Don8L4DTVrUrRAcVTsFoCRqei5Mokde3CV3K9Ut4nAGZ';
const amount = '42';
await KinSdk.sendPayment(env, { secret, destination, amount, memo: 'Accept my Don8ion' });
```

## Support

If you have any issues feel free to join the #react-native channel in the [Kintegrate Discord](https://discord.gg/Mpc7bFtWd5).
