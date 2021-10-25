import React, { useEffect, useState, VFC } from 'react';

import { KinSDKService } from '../../KinSDKService';
import { View } from 'react-native';
import { AccountCreate } from '../src/AccountCreate';
import { AccountListItem } from '../src/AccountListItem';
import type { KinAccount } from '../../interfaces/kin-account.interface';
import { db } from '../../db/app-database';
import { KinEnvironment } from '@kin-sdk/react-native';

export const AccountList: VFC = () => {
  const [accounts, setAccounts] = useState<KinAccount[]>();

  // New instance of our KinSDK wrapper
  const [kin] = useState<KinSDKService>(() => new KinSDKService(KinEnvironment.Test));

  const onDeleteAccount = async (account: KinAccount) => {
    await db.deleteAccount(account.id);
    await db.getAccounts().then(setAccounts);
  };

  // Step 1: Create a new random keypair and store in the DB
  const onGenerateKeypair = async () => {
    try {
      const keys = await kin.randomKeyPair();
      const created = await db.storeAccount(keys);
      await db.getAccounts().then(setAccounts);
      console.log('Created Keypair', created);
    } catch (e) {
      console.log(`An error occurred`, e);
    }
  };

  // Step 2: Create an account on the Blockchain using the Secret from our keypair
  const onCreateAccount = async (account: KinAccount) => {
    try {
      kin.createAccount(account.secret).then((result: any) => {
        console.log('Account created on Blockchain', result);
      });
    } catch (e) {
      console.log(`An error occurred`, e);
    }
  };

  // Step 3: Resolve accounts to check if they exist, and get the balance
  const onResolveAccounts = (account: KinAccount) => {
    return kin
      .resolveTokenAccounts(account.publicKey)
      .then((res) => console.log('Balance retrieved from Blockchain', res));
  };

  // Step 4: Request and airdrop to receive a bit of Kin
  const onRequestAirdrop = (account: KinAccount) => {
    return kin
      .requestAirdrop(account.publicKey, '100')
      .then((res) => console.log('Airdrop requested from Blockchain', res));
  };

  // Step 5: Submit a payment
  const submitPayment = async (account: KinAccount) => {
    const destination = 'GA6CCT5IB4DJBR63BM3BQ7WB3M2UZ6QG6Z5XB64GSIABH6ICIETTAVU2';
    const amount = '2';
    const memo = 'Test Memo!';

    // Call out to our SDK's submitPayment method
    return kin.submitPayment(account.secret, destination, amount, memo).then((result) => {
      console.log('Payment submitted on Blockchain', result);
    });
  };

  useEffect(() => {
    if (!accounts) {
      db.getAccounts().then(setAccounts);
    }
  }, [accounts]);

  return (
    <View>
      <AccountCreate onCreate={onGenerateKeypair} />
      {accounts?.map((account) => (
        <AccountListItem
          key={account.id}
          account={account}
          createAccount={onCreateAccount}
          deleteAccount={onDeleteAccount}
          resolveAccounts={onResolveAccounts}
          requestAirdrop={onRequestAirdrop}
          submitPayment={submitPayment}
        />
      ))}
    </View>
  );
};
