import Foundation

import Promises

import KinBase

@objc(KinSdk)
class KinSdk: NSObject {
    
    private static let enableTestMigration: Bool = true
    private static let useKin2: Bool = false
    
    private let testEnv = KinEnvironment.Agora.testNet(minApiVersion: 4)
    private let prodEnv = KinEnvironment.Agora.mainNet(minApiVersion: 4)
    
    private var watchContext: KinAccountContext! = nil
    
    func getEnv(env: String) -> KinEnvironment {
        if env == "Test" {
            return testEnv
        } else {
            return prodEnv
        }
    }
    
    func kinAccount(_ accountId: String) -> PublicKey {
        return PublicKey(base58: accountId) ?? PublicKey(stellarID: accountId)!
    }
    
    @objc(generateRandomKeyPair:withRejecter:)
    func generateRandomKeyPair(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let key = KeyPair.generate()
        let result: NSMutableDictionary = [:]
        result["secret"] = key?.seed?.base58
        result["publicKey"] = key?.publicKey.base58
        
        resolve(result)
    }
    
    @objc(createNewAccount:withInput:withResolver:withRejecter:)
    func createNewAccount(env: String, input: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let seed = Seed(base58: input["secret"] as! String)!
        let key = KeyPair(seed: seed)
        guard let context = (try? KinAccountContext
                .Builder(env: getEnv(env: env))
                .importExistingPrivateKey(key)
                .build()) else {
            resolve(false)
            return
        }
        self.watchContext = context
        
        resolve(true)
    }
    
    @objc(sendPayment:withInput:withResolver:withRejecter:)
    func sendPayment(env: String, input: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        
        do {
            let seed = Seed(base58: input["secret"] as! String)!
            let key = KeyPair(seed: seed)
            
            let env = getEnv(env: env)
            let accountContext = try KinAccountContext
                .Builder(env: env)
                .importExistingPrivateKey(key)
                .build()
            
            guard let amount = Kin(string: input["amount"] as! String) else {
                reject("Error", "invalid amount", NSError())
                return
            }
            
            let item = KinPaymentItem(amount: amount, destAccount: kinAccount(input["destination"] as! String))
            accountContext.sendKinPayment(item, memo: KinMemo(text: input["memo"] as? String ?? ""))
                .then(on: .main) {payment in
                    resolve((self.toDict(payment) as NSDictionary).mutableCopy() as! NSMutableDictionary)
                }
                .catch(on: .main) {error in
                    reject("Error", "invalid destination", error as NSError)
                }
            
        } catch {
            reject("Error", "invalid secret", error as NSError)
        }
    }
    
    @objc(sendInvoicedPayment:withInput:withResolver:withRejecter:)
    func sendInvoicedPayment(env: String, input: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        
        do {
            let seed = Seed(base58: input["secret"] as! String)!
            let key = KeyPair(seed: seed)
            
            let env = getEnv(env: env)
            let accountContext = try KinAccountContext
                .Builder(env: env)
                .importExistingPrivateKey(key)
                .build()
            
            var appIndex: AppIndex = .init(value: 0)
            if let index = input["appIndex"] as? Int {
                appIndex = .init(value: UInt16(index))
            }
            
            let requestItems = input["lineItems"] as! NSArray
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
            
            accountContext.payInvoice(processingAppIdx: appIndex, destinationAccount: kinAccount(input["destination"] as! String), invoice: try Invoice(lineItems: lineItems))
                .then(on: .main) {payment in
                    resolve((self.toDict(payment) as NSDictionary).mutableCopy() as! NSMutableDictionary)
                }
                .catch(on: .main) {error in
                    reject("Error", "invalid destination", error as NSError)
                }
            
            
        } catch {
            reject("Error", "invalid input data", error as NSError)
        }
    }
    
    @objc(resolveTokenAccounts:withInput:withResolver:withRejecter:)
    func resolveTokenAccounts(env: String, input: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let env = getEnv(env: env)
        guard let publicKey = input["publicKey"] as? String else {
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
                result["address"] = account.publicKey.base58
                result["balance"] = "\(account.balance.amount)"
                resolve(result)
            }.catch {error in
                reject("Error", error.localizedDescription, error as NSError)
            }
    }
    
    @objc(requestAirdrop:withInput:withResolver:withRejecter:)
    func requestAirdrop(env: String, input: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let publicKey = input["publicKey"] as? String else {
            reject("Error", "invalid publicKey", NSError())
            return
        }
        guard let amount = input["amount"] as? String else {
            reject("Error", "invalid amount", NSError())
            return
        }
        let key = kinAccount(publicKey)
        let env = getEnv(env: env)
        env.testService!.fundAccount(key, amount: Decimal(string: amount)!)
            .then { _ in
                print("fundAccount: funded")
                resolve(true)
            }
            .catch { error in
                print("fundAccount error -> ", error.localizedDescription)
                reject("Error", error.localizedDescription, error as NSError)
            }
    }
    
    @objc(watchBalance:withPublicKey:withCallback:)
    func watchBalance(env: String, publicKey: String, callback: @escaping (NSMutableDictionary) -> Void) {
        
        self.watchContext?.observeBalance(mode: .active)
            .subscribe { balance in
                callback((self.balanceToDict(balance) as NSDictionary).mutableCopy() as! NSMutableDictionary)
            }
        
    }
    
    func toDict(_ payment: KinPayment) -> [String:Any] {
        let mirror = Mirror(reflecting: payment)
        var dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        dict["sourceAccountId"] = payment.sourceAccount.base58
        dict["destAccountId"] = payment.destAccount.base58
        return dict
    }
    
    func balanceToDict(_ balance: KinBalance) -> [String:Any] {
        let mirror = Mirror(reflecting: balance)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?, value:Any) -> (String, Any)? in
            guard let label = label else { return nil }
            return (label, value)
        }).compactMap { $0 })
        return dict
    }
}
