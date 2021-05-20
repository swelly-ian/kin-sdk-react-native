# @kin-sdk/react-native

React Native Kin SDK wrapper for the official Android and iOS Kin SDK's

## Demo applications

If you want to implement the Kin React Native SDK in your applications, you probably want to start out with the demo application:

- [Kin SDK React Native Demo](https://github.com/kin-sdk/kin-sdk-demo-react-native)

## Usage

In this section you can read how to use the Kin React Native SDK in your project.

### Step 0: Install dependencies

You need to install the `@kin-sdk/react-native` package to your project:

```shell
yarn add @kin-sdk/react-native
# Or if you are using npm
npm install @kin-sdk/react-native
```

### Step 1: Initializing the Kin Client

The first thing you need to do is import the `KinSdk` and environment into your project, and set up a reference to the environment:

```typescript
// Import the client
import { KinEnvironment, KinSdk } from '@kin-sdk/react-native';
// Set up the environment
const env = KinEnvironment.Test;
```

### Step 2: Generate a new key pair

In order to interact with the blockchain you need a key pair that consists of a `secret` and `publicKey`.

This account will generally be stored on the users' device. Make sure that the user has a way to export their secret, so they won't lose access to their Kin.

```typescript
// Create a key pair
const { secret, publicKey } = KinSdk.generateRandomKeyPair();
```

### Step 3: Create an account on Kin blockchain

Use the `secret` of the account you generated in the previous step to create the account on the blockchain.

> Creating the account may take a little while (up to 30 seconds, possibly longer on a busy moment) after the `result` above has been returned. You can use the `getBalances` method (see next step) to make sure the account is in fact created. As soon as the account is created correctly, the `getBalances` method will return the address with the balance.

```typescript
// Create the account
const [res, err1] = await KinSdk.createNewAccount(env, { secret });

if (err1) {
  // handle error 1
}
```

### Step 4: Get balances

The next step is retrieving the balances. Kin is a token on the Solana blockchain, and your Solana Account can consist of various 'balances' or 'token accounts'. You can [read more details here](https://docs.kin.org/solana#token-accounts).

```typescript
// Retrieve balances from account
const [accounts, err2] = await KinSdk.resolveTokenAccounts(env, { publicKey });

if (err2) {
  // handle error 2
}
```

### Step 5: Submit a payment.

After this is done, you are ready to submit a payment.

The memo field here is optional, the other fields are required.

```typescript
const secret = account.secret;
const tokenAccount = account.publicKey;
const destination = 'Don8L4DTVrUrRAcVTsFoCRqei5Mokde3CV3K9Ut4nAGZ';
const amount = '42';
const memo = 'One Kin as a Donation';
await KinSdk.sendPayment(env, { secret, destination, amount, memo });
```

## Support

If you have any issues feel free to join the #react-native channel in the [Kintegrate Discord](https://discord.gg/Mpc7bFtWd5).
