/**
 * This is the service we will actually use in our app.
 *
 * It wraps around the KinSdk Native Wrapper
 */

import { KinEnvironment, KinSdk } from '@kin-sdk/react-native';

export class KinSDKService {
  constructor(protected readonly env: KinEnvironment) {
    console.log(`KinSDK Connected to ${env}`);
  }

  // Function to return random key pair that we can store in our local DB
  randomKeyPair(): Promise<{ secret: string; publicKey: string }> {
    console.log('KinSDKService::randomKeyPair()');

    return KinSdk.generateRandomKeyPair();
  }

  // Create account on the Kin Blockchain
  createAccount(secret: string): Promise<boolean> {
    console.log('KinSDKService::createAccount()', secret);

    return KinSdk.createNewAccount(this.env, { secret });
  }

  // Resolve the token accounts of this public key on the Blockchain
  resolveTokenAccounts(
    publicKey: string
  ): Promise<
    Array<{
      address: string;
      balance: string;
    }>
  > {
    console.log('KinSDKService::resolveTokenAccounts()', publicKey);

    return KinSdk.resolveTokenAccounts(this.env, { publicKey });
  }

  requestAirdrop(publicKey: string, amount: string): Promise<boolean> {
    console.log('KinSDKService::requestAirdrop()', { publicKey, amount });

    return KinSdk.requestAirdrop(this.env, { amount, publicKey });
  }

  // Submit a payment to the Blockchain
  submitPayment(secret: string, destination: string, amount: string, memo: string, appIndex: number | null = null): Promise<object> {
    console.log('KinSDKService::submitPayment()', { secret, destination, amount, memo, appIndex});

    return KinSdk.sendPayment(this.env, { secret, destination, amount, memo, appIndex: 0 });

    /**
     * paymentType: 2 (Spend)
     */
    // const lineItems = [
    //   {
    //     description: 'One Hamburger',
    //     amount: 2.00
    //   },
    //   {
    //     description: 'Tip the waitress',
    //     amount: 0.50
    //   },
    // ];
    // return KinSdk.sendInvoicedPayment(this.env, { secret, lineItems, destination, paymentType: 2, appIndex: 0 });
  }

  static watchBalance(env: KinEnvironment, publicKey: string, callback: (balance: object) => void ): void {
    KinSdk.watchBalance(
      env,
      publicKey,
      callback,
    );
  }
}
