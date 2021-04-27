import * as React from 'react';

import { SafeAreaView, ScrollView, StatusBar, useColorScheme } from 'react-native';
import { Colors } from 'react-native/Libraries/NewAppScreen';
import { AccountList } from './wallet/feature/AccountList';
import { AppDatabaseGuard } from './AppDatabaseGuard';

export default function App() {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <ScrollView contentInsetAdjustmentBehavior="automatic" style={backgroundStyle}>
        <AppDatabaseGuard>
          <AccountList />
        </AppDatabaseGuard>
      </ScrollView>
    </SafeAreaView>
  );
}
