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
    public static func sendPayment(env: String, request: NSDictionary, resolve: @escaping (NSMutableDictionary) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        
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
            
            let item = KinPaymentItem(amount: amount, destAccountId: kinAccount(request["destination"] as! String))
            accountContext.sendKinPayment(item, memo: KinMemo(text: request["memo"] as? String ?? ""))
                .then(on: .main) {payment in
                    resolve((toDict(payment) as NSDictionary).mutableCopy() as! NSMutableDictionary)
                }
                .catch(on: .main) {error in
                    reject("Error", "invalid destination", error as NSError)
                }
            
        } catch {
            reject("Error", "invalid secret", error as NSError)
        }
    }
    
    @objc(sendInvoice::::)
    public static func sendInvoice(env: String, request: NSDictionary, resolve: @escaping (NSMutableDictionary) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        
        do {
            let key = try KinAccount.Key(secretSeed: request["secret"] as! String)
            
            let env = getEnv(env: env)
            let accountContext = try KinAccountContext
                .Builder(env: env)
                .importExistingPrivateKey(key)
                .build()
            
            var appIndex: AppIndex = .init(value: 0)
            if let index = request["appIndex"] as? Int {
                appIndex = .init(value: UInt16(index))
            }
            
            let requestItems = request["lineItems"] as! NSArray
            var lineItems: [LineItem] = []
            for item in requestItems {
                let requestItem = item as! [String: Any]
                let itemDes = requestItem["description"] as! String
                let itemAmount = requestItem["amount"] as! Double
                guard let amount = Kin(string: String(itemAmount)) else
                {
                    reject("Error", "invalid amount", NSError())
                    return
                }
                lineItems.append(try LineItem(title: itemDes, amount: amount))
            }
            
            accountContext.payInvoice(processingAppIdx: appIndex, destinationAccount: kinAccount(request["destination"] as! String), invoice: try Invoice(lineItems: lineItems))
                .then(on: .main) {payment in
                    resolve((toDict(payment) as NSDictionary).mutableCopy() as! NSMutableDictionary)
                }
                .catch(on: .main) {error in
                    reject("Error", "invalid destination", error as NSError)
                }
            
            
        } catch {
            reject("Error", "invalid input data", error as NSError)
        }
    }
    
    @objc(getBalance::::)
    public static func getBalance(env: String, account: NSDictionary, resolve: @escaping (NSMutableDictionary) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        let env = getEnv(env: env)
        guard let publicKey = account["publicKey"] as? String else {
            reject("Error", "invalid publicKey", NSError())
            return
        }
        
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
                reject("Error", error.localizedDescription, error as NSError)
            }
    }
    
    @objc(fundAccount::::)
    public static func fundAccount(env: String, account: NSDictionary, resolve: @escaping (Bool) -> Void, reject: @escaping (String, String, NSError) -> Void) {
        guard let publicKey = account["publicKey"] as? String else {
            reject("Error", "invalid publicKey", NSError())
            return
        }
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
        
        
    }
    
    @objc(watchBalance:::)
    public static func watchBalance(env: String, publicKey: String, callback: @escaping (NSMutableDictionary) -> Void) {
        
        let key = kinAccount(publicKey)
        let env = getEnv(env: env)
        
        let accountContext = KinAccountContext
            .Builder(env: env)
            .useExistingAccount(key)
            .build()
        
        accountContext.observeBalance(mode: .active)
            .subscribe { balance in
                callback((balanceToDict(balance) as NSDictionary).mutableCopy() as! NSMutableDictionary)
            }
        
    }
    
    static func toDict(_ payment: KinPayment) -> [String:Any] {
        let mirror = Mirror(reflecting: payment)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        return dict
    }
    
    static func balanceToDict(_ balance: KinBalance) -> [String:Any] {
        let mirror = Mirror(reflecting: balance)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        return dict
    }
    
}
