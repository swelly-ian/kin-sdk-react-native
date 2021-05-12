import { NativeModules } from 'react-native';

export enum KinEnvironment {
  Prod = 'Prod',
  Test = 'Test'
}

export interface CreateNewAccountRequest {
  secret: string;
}

export interface SendPaymentRequest {
  secret: string;
  destination: string;
  amount: string;
  memo?: string;
  appIndex: number | null;
}

export interface SendInvoiceRequest {
  secret: string;
  lineItems: Array<LineItem>;
  destination: string;
  paymentType: number | null;
  appIndex: number | null;
}

interface LineItem {
  description: string;
  amount: number;
}

export interface GenerateKeyPairResult {
  secret: string;
  publicKey: string;
}

export type CreateNewAccountResult = boolean;
export type RequestAirdropResult = boolean;
export type SendPaymentResult = object;

export interface RequestAirdropRequest {
  publicKey: string;
  amount: string;
}
export interface ResolveTokenAccountsRequest {
  publicKey: string;
}
export interface ResolveTokenAccountsResultItem {
  address: string;
  balance: string;
}

export type ResolveTokenAccountsResult = ResolveTokenAccountsResultItem[];

export type KinSdkType = {
  generateRandomKeyPair: () => Promise<GenerateKeyPairResult>;
  createNewAccount: (env: KinEnvironment, input: CreateNewAccountRequest) => Promise<CreateNewAccountResult>;
  requestAirdrop: (env: KinEnvironment, input: RequestAirdropRequest) => Promise<RequestAirdropResult>;
  resolveTokenAccounts: (
    env: KinEnvironment,
    input: ResolveTokenAccountsRequest
  ) => Promise<ResolveTokenAccountsResult>;
  sendPayment: (env: KinEnvironment, input: SendPaymentRequest) => Promise<SendPaymentResult>;
  sendInvoice: (env: KinEnvironment, input: SendInvoiceRequest) => Promise<SendPaymentResult>;

  watchBalance: (env: KinEnvironment, publicKey: string, callback: (balance: object) => void) => void;
};

export const { KinSdk }: { KinSdk: KinSdkType } = NativeModules as any;

export default KinSdk as KinSdkType;
