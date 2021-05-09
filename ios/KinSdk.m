#import <React/RCTBridgeModule.h>
@import KinSDK;


@interface RCT_EXTERN_MODULE(KinSdk, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

//RCT_EXTERN_METHOD(generateRandomKeyPair:(RCTPromiseResolveBlock)resolve
//                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXPORT_METHOD(generateRandomKeyPair:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {
    [KinSDKUtils generateRandomKeyPair: ^(NSDictionary* success) {
        resolve (success);
    } : ^(NSString *code, NSString *event, NSError *error) {
        reject (code, event, error);
    }];
}

RCT_EXPORT_METHOD(createNewAccount: (NSString *)env
                  account: (NSDictionary *)account
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"Using initWithFormat:   %@\n", account);
    [KinSDKUtils createAccount: env : account : ^(bool success) {
        resolve (@(success));
    } : ^(NSError *error) {
        reject (@"Error", @"Invalid secret", error);
    } ];
}

RCT_EXPORT_METHOD(resolveTokenAccounts: (NSString *)env
                  account: (NSDictionary *)account
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {
    [KinSDKUtils getBalance: env : account : ^(NSDictionary* success) {
        resolve (success);
    } : ^(NSString *code, NSString *event, NSError *error) {
        reject (code, event, error);
    }];
}

RCT_EXPORT_METHOD(sendPayment: (NSString *)env
                  request: (NSDictionary *)request
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {

    [KinSDKUtils sendPayment: env : request : ^(NSDictionary* success) {
        resolve (success);
    } : ^(NSString *code, NSString *event, NSError *error) {
        reject (code, event, error);
    }];
}

RCT_EXPORT_METHOD(sendInvoice: (NSString *)env
                  request: (NSDictionary *)request
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {

    [KinSDKUtils sendInvoice: env : request : ^(NSDictionary* success) {
        resolve (success);
    } : ^(NSString *code, NSString *event, NSError *error) {
        reject (code, event, error);
    }];
}

RCT_EXPORT_METHOD(requestAirdrop: (NSString *)env
                  request: (NSDictionary *)request
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject) {

    [KinSDKUtils fundAccount: env : request : ^(bool success) {
        resolve (@(success));
    } : ^(NSString *code, NSString *event, NSError *error) {
        reject (code, event, error);
    }];
}

RCT_EXPORT_METHOD(watchBalance: (NSString *)env
                  publicKey: (NSString *)publicKey
                  callback:(RCTResponseSenderBlock)callback) {

    [KinSDKUtils watchBalance: env : publicKey : ^(NSDictionary* balance) {
        callback (@[balance]);
    }];
}

@end
