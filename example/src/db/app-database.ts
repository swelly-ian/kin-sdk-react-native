import type { KinAccount } from '../interfaces/kin-account.interface';
import AsyncStorage from '@react-native-async-storage/async-storage';
const generateId = (size = 8) => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

export class AppDatabase {
  readonly accountKey = '@@KinAccounts';
  initialized = false;

  constructor() {
    console.log('AppDatabase Created');
  }

  async init(): Promise<boolean> {
    console.log('AppDatabase::init()');

    this.initialized = true;

    const accounts = await this.getAccounts();
    console.log('accounts', accounts);

    return Promise.resolve(true);
  }

  async getAccounts(): Promise<KinAccount[]> {
    try {
      const jsonValue = await AsyncStorage.getItem(this.accountKey);
      const result: KinAccount[] = jsonValue !== null ? JSON.parse(jsonValue) : [];

      return Promise.resolve(result);
    } catch (e) {
      return Promise.reject(`Could not parse accounts`);
    }
  }

  async storeAccounts(accounts: KinAccount[]): Promise<KinAccount[]> {
    try {
      await AsyncStorage.setItem(this.accountKey, JSON.stringify(accounts));

      return Promise.resolve(this.getAccounts());
    } catch (e) {
      return Promise.reject(`Could not parse accounts`);
    }
  }

  async storeAccount({ secret, publicKey }: { secret: string; publicKey: string }) {
    const id = generateId();
    const account: KinAccount = {
      id,
      secret,
      publicKey,
      name: 'Account ' + id,
      tokenAccounts: []
    };
    const accounts = await this.getAccounts();
    await this.storeAccounts([...accounts, account]);

    return account;
  }

  async deleteAccount(id: string) {
    const accounts = await this.getAccounts();
    await this.storeAccounts([...accounts.filter((item) => item.id !== id)]);
    return true;
  }
}

export const db = new AppDatabase();
