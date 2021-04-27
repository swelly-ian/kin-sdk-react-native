export interface KinAccount {
  id: string;
  secret: string;
  name: string;
  publicKey: string;
  tokenAccounts: KinTokenAccount[];
}

export interface KinTokenAccount {
  balance: string;
  address: string;
}
