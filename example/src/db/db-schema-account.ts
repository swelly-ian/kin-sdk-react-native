import type { RxJsonSchema } from 'rxdb';
import type { KinAccount } from '../interfaces/kin-account.interface';

export const accountSchema: RxJsonSchema<KinAccount> = {
  title: 'Account Schema',
  description: 'Describes an account',
  version: 0,
  keyCompression: true,
  type: 'object',
  indexes: ['name'],
  properties: {
    id: {
      type: 'string',
      primary: true
    },
    name: {
      type: 'string'
    },
    publicKey: {
      type: 'string'
    },
    secret: {
      type: 'string'
    },
    tokenAccounts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          publicKey: {
            type: 'string'
          },
          balance: {
            type: 'number'
          }
        }
      }
    }
  },
  required: ['id', 'name', 'publicKey']
};
