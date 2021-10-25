#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(KinSdk, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(generateRandomKeyPair:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(createNewAccount: (NSString *)env
                  withInput: (NSDictionary *)input
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(resolveTokenAccounts: (NSString *)env
                  withInput: (NSDictionary *)input
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(sendPayment: (NSString *)env
                  withInput: (NSDictionary *)input
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(sendInvoicedPayment: (NSString *)env
                  withInput: (NSDictionary *)input
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(requestAirdrop: (NSString *)env
                  withInput: (NSDictionary *)input
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(watchBalance: (NSString *)env
                  withPublicKey: (NSString *)publicKey
                  callback:(RCTResponseSenderBlock)callback)

@end
