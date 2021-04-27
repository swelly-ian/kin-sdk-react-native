import stellarsdk
import Promises

//import KinSDK

@objc(KinSdk)
class KinSdk: NSObject {
    
    let enableTestMigration: Bool = true
    let useKin2: Bool = false

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }
    
    @objc(generateRandomKeyPair:withRejecter:)
    func generateRandomKeyPair(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        do {
            let key = try KeyPair.generateRandomKeyPair()
            let result: NSMutableDictionary = [:]
            result["secret"] = key.secretSeed
            result["publicKey"] = key.accountId
            resolve(result)
        } catch {
            reject("no_events", "There were no events", error)
        }
    }
    
//    @objc(createNewAccount:withResolver:withRejecter:)
//    func createNewAccount(secretSeed: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
//        KinSDK.create
//    }
}
