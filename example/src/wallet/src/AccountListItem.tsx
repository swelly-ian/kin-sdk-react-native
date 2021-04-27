import React, { FC } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';
import type { KinAccount } from '../../interfaces/kin-account.interface';

export const AccountListItem: FC<{
  account: KinAccount;
  createAccount: (account: KinAccount) => Promise<void>;
  deleteAccount: (account: KinAccount) => Promise<void>;
  resolveAccounts: (account: KinAccount) => Promise<void>;
  requestAirdrop: (account: KinAccount) => Promise<void>;
  submitPayment: (account: KinAccount) => Promise<void>;
}> = ({ account, createAccount, deleteAccount, resolveAccounts, requestAirdrop, submitPayment }) => {
  const handleCreateAccount = () => createAccount(account);
  const handleDeleteAccount = () => deleteAccount(account);
  const handleSubmitPayment = () => submitPayment(account);
  const handleResolveTokenAccounts = () => resolveAccounts(account);
  const handleRequestAirdrop = () => requestAirdrop(account);

  return (
    <View style={styles.accountContainer}>
      <Text style={styles.accountPublicKey}>{account.id}</Text>
      <View style={styles.accountButtons}>
        <Button title={'2. Create Account'} onPress={handleCreateAccount} />
        <Button title={'3. Resolve TokenAccounts'} onPress={handleResolveTokenAccounts} />
      </View>
      <View style={styles.accountButtons}>
        <Button title={'4. Request Airdrop'} onPress={handleRequestAirdrop} />
        <Button title={'5. Submit Payment'} onPress={handleSubmitPayment} />
      </View>
      <View style={styles.accountButtons}>
        <Button title={'Delete Account'} onPress={handleDeleteAccount} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  accountContainer: {
    borderBottomWidth: 1,
    paddingHorizontal: 24
  },
  accountPublicKey: {
    marginVertical: 8,
    fontSize: 18,
    fontWeight: '400'
  },
  accountButtons: {
    flex: 1,
    flexDirection: 'row'
  }
});
