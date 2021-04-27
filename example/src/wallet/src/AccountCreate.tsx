import React, { FC } from 'react';
import { Button, StyleSheet, View } from 'react-native';

export const AccountCreate: FC<{ onCreate: () => void }> = ({ onCreate }) => {
  return (
    <View style={styles.walletContainer}>
      <Button title="1. Create" onPress={onCreate} />
    </View>
  );
};

const styles = StyleSheet.create({
  walletContainer: {
    borderBottomWidth: 1,
    paddingHorizontal: 24
  }
});
