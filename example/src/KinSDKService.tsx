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

    // return Promise.resolve({ secret: 'x', publicKey: 'y ' });
    return KinSdk.generateRandomKeyPair();
  }

  // Create account on the Kin Blockchain
  createAccount(secret: string): Promise<boolean> {
    console.log('KinSDKService::createAccount()', secret);

    // return Promise.resolve(true);
    return KinSdk.createNewAccount(this.env, { secret });
    // return KinSdk.createNewAccount(this.env, { secret: 'Test' });
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

    // return Promise.resolve([]);
    // TODO 3: Implement KinSdk.resolveTokenAccounts(this.env, { publicKey })
    // return KinSdk.resolveTokenAccounts(this.env, { publicKey: "Test" });
    return KinSdk.resolveTokenAccounts(this.env, { publicKey });
  }

  requestAirdrop(publicKey: string, amount: string): Promise<boolean> {
    console.log('KinSDKService::requestAirdrop()', { publicKey, amount });

    // return Promise.resolve(true);
    // TODO 4: Implement KinSdk.requestAirdrop(this.env, { amount, publicKey })
    return KinSdk.requestAirdrop(this.env, { amount, publicKey });
    // return KinSdk.requestAirdrop(this.env, { amount, publicKey: "Test" });
  }

  // Submit a payment to the Blockchain
  submitPayment(secret: string, destination: string, amount: string, memo: string, app_index: number | null = null): Promise<object> {
    console.log('KinSDKService::submitPayment()', { secret, destination, amount, memo, app_index});

    // return KinSdk.sendPayment(this.env, { secret, destination, amount, memo, app_index: 1 });

    /**
     * paymentType: 2 (Spend)
     */
    const paymentItems = [
      {
        description: 'One Hamburger',
        amount: 2.00
      },
      {
        description: 'Tip the waitress',
        amount: 0.50
      },
    ];
    return KinSdk.sendInvoice(this.env, { secret, paymentItems, destination, paymentType: 2, app_index: 0 });



    // return KinSdk.sendPayment(this.env, { secret: "11", destination, amount: "aa", memo });
    // return KinSdk.sendPayment(this.env, { secret: "11", destination1: "32", amount: "aa", memo });
    // return KinSdk.sendPayment(this.env, { secret, destination, amount: "aa", memo });
  }

  static watchBalance(env: KinEnvironment, publicKey: string, callback: (balance: object) => void ): void {
    KinSdk.watchBalance(
      env,
      publicKey,
      callback,
    );
  }
}
