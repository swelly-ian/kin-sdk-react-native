import Foundation

import stellarsdk
import Promises

import KinBase
import Base58Swift

@objc(KinSDKUtils)
public class KinSDKUtils: NSObject {
    
    private static let enableTestMigration: Bool = true
    private static let useKin2: Bool = false
    
    private static let testEnv = KinEnvironment.Agora.testNet(minApiVersion: 4, useKin2: false, testMigration: false)
    private static let prodEnv = KinEnvironment.Agora.mainNet(minApiVersion: 4)
    
//    @objc(generateRandomKeyPair)
//    public static func generateRandomKeyPair() -> [String] {
//        do {
//            let key = try KeyPair.generateRandomKeyPair()
//            return [key.secretSeed, key.publicKey.accountId]
//        } catch {
//            return []
//        }
//    }
    
    static func getEnv(env: String) -> KinEnvironment {
        if env == "Test" {
            return testEnv
        } else {
            return prodEnv
        }
    }
    
    static func kinAccount(_ accountId: String) -> KinAccount.Id {
        guard let bytes = Base58Swift.Base58.base58Decode(accountId) else { return KinAccount.Id(accountId) }
        
        do {
            let publicKey = try PublicKey(bytes)
            return KinAccount.Id(publicKey.accountId)
        } catch {
            return KinAccount.Id(accountId)
        }
    }
    
    @objc(generateRandomKeyPair::)
    public static func generateRandomKeyPair(resolve: @escaping (NSMutableDictionary) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        do {
            let key = try KeyPair.generateRandomKeyPair()
            let result: NSMutableDictionary = [:]
            result["secret"] = key.secretSeed
            result["publicKey"] = Base58Swift.Base58.base58Encode(key.publicKey.bytes)
            resolve(result)
        } catch {
            reject("no_events", "There were no events", error as NSError)
        }
    }
    
    @objc(createAccount::::)
    public static func createAccount(env: String, account: NSDictionary, resolve: @escaping (Bool) -> Void, reject: @escaping (NSError) -> Void) {
        do {
            let key = try KinAccount.Key(secretSeed: account["secret"] as! String)
            guard (try? KinAccountContext
                    .Builder(env: getEnv(env: env))
                    .importExistingPrivateKey(key)
                    .build()) != nil else {
                resolve(false)
                return
            }
        } catch {
            reject(error as NSError)
            return
        }
        
        resolve(true)
    }
    
    @objc(sendPayment::::)
    public static func sendPayment(env: String, request: NSDictionary, resolve: @escaping (Bool) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        
        do {
            let key = try KinAccount.Key(secretSeed: request["secret"] as! String)
            
            let env = getEnv(env: env)
            let accountContext = try KinAccountContext
                .Builder(env: env)
                .importExistingPrivateKey(key)
                .build()
            
            guard let amount = Kin(string: request["amount"] as! String) else {
                reject("Error", "invalid amount", NSError())
                return
            }
            
            let item = KinPaymentItem(amount: amount, destAccountId: request["destination"] as! String)
            accountContext.sendKinPayment(item, memo: KinMemo(text: request["memo"] as? String ?? ""))
                .then(on: .main) {_ in
                    resolve(true)
                }
                .catch(on: .main) {error in
                    reject("Error", "invalid destination", error as NSError)
                }
            
        } catch {
            reject("Error", "invalid secret", error as NSError)
        }
    }
    
    @objc(getBalance::::)
    public static func getBalance(env: String, account: NSDictionary, resolve: @escaping (NSMutableDictionary) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        let env = getEnv(env: env)
        guard let publicKey = account["publicKey"] as? String else {
            reject("Error", "invalid publicKey", NSError())
            return
        }

//        do {
//            _ = try PublicKey(accountId: publicKey)
            let key = kinAccount(publicKey)
            let accountContext = KinAccountContext
                .Builder(env: env)
                .useExistingAccount(key)
                .build()
            accountContext.getAccount(forceUpdate: true)
                .then { account in
                    let result: NSMutableDictionary = [:]
                    result["address"] = account.id
                    result["balance"] = "\(account.balance.amount)"
                    resolve(result)
                }.catch {error in
    //                let result: NSMutableDictionary = [:]
    //                result["address"] = ""
    //                result["balance"] = ""
    //                callback(result)
                    reject("Error", error.localizedDescription, error as NSError)
                }
//        } catch {
//            reject("Error", error.localizedDescription, error as NSError)
//        }
        
//        env.service.resolveTokenAccounts(accountId: KinAccount.Id(account["publicKey"] as! String)).then { accounts in
//            callback(accounts.map {
//                let result: NSMutableDictionary = [:]
//                result["address"] = $0.accountId
//                result["balance"] = $0.b
//                result
//            })
//        }
    }
    
    @objc(fundAccount::::)
    public static func fundAccount(env: String, account: NSDictionary, resolve: @escaping (Bool) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        guard let publicKey = account["publicKey"] as? String else {
            reject("Error", "invalid publicKey", NSError())
            return
        }
//        do {
//            _ = try PublicKey(accountId: publicKey)
            let key = kinAccount(publicKey)
            let env = getEnv(env: env)
            env.testService!.fundAccount(key)
                .then { _ in
                    print("fundAccount: funded")
                    resolve(true)
                }
                .catch { error in
                    print("fundAccount error -> ", error.localizedDescription)
                    reject("Error", error.localizedDescription, error as NSError)
                }
//        } catch {
//            reject("Error", error.localizedDescription, error as NSError)
//        }
        
        
    }
    
}
