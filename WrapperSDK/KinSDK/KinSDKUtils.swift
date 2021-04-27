import Foundation

import stellarsdk
import Promises

import KinBase

@objc(KinSDKUtils)
public class KinSDKUtils: NSObject {
    
    private static let enableTestMigration: Bool = true
    private static let useKin2: Bool = false
    
    @objc(generateRandomKeyPair)
    public static func generateRandomKeyPair() -> [String] {
        do {
            let key = try KeyPair.generateRandomKeyPair()
            return [key.secretSeed, key.publicKey.accountId]
        } catch {
            return []
        }
    }
    
    @objc(createAccount:)
    public static func createAccount(account: NSDictionary) -> Bool {
        do {
            let key = try KinAccount.Key(secretSeed: account["secret"] as! String)
            guard (try? KinAccountContext
                    .Builder(env: KinEnvironment.Agora.testNet(useKin2: useKin2, testMigration: enableTestMigration))
                    .importExistingPrivateKey(key)
                    .build()) != nil else {
                return false
            }
        } catch {
            return false
        }
        

        return true
    }
    
    @objc(sendPayment::)
    public static func sendPayment(_ request: NSDictionary, callback: @escaping (Bool) -> Void) {
        
        do {
            let key = try KinAccount.Key(secretSeed: request["secret"] as! String)
            
            let env = KinEnvironment.Agora.testNet(useKin2: useKin2, testMigration: enableTestMigration)
            let accountContext = try KinAccountContext
                .Builder(env: env)
                .importExistingPrivateKey(key)
                .build()
            
            guard let amount = Kin(string: request["amount"] as! String) else {
                callback(false)
                return
            }
            
            let item = KinPaymentItem(amount: amount, destAccountId: request["destination"] as! String)
            accountContext.sendKinPayment(item, memo: KinMemo(text: request["memo"] as? String ?? ""))
                .then(on: .main) {_ in
                    callback(true)
                }
                .catch(on: .main) {error in
                    callback(false)
                }
            
        } catch {
            callback(false)
        }
    }
    
    @objc(getBalance::)
    public static func getBalance(_ account: NSDictionary, callback: @escaping (NSMutableDictionary) -> Void) {
        let env = KinEnvironment.Agora.testNet(useKin2: useKin2, testMigration: enableTestMigration)
        let accountContext = KinAccountContext
            .Builder(env: env)
            .useExistingAccount(KinAccount.Id(account["publicKey"] as! String))
            .build()
        accountContext.getAccount(forceUpdate: true)
            .then { account in
                let result: NSMutableDictionary = [:]
                result["address"] = account.id
                result["balance"] = account.balance
                callback(result)
            }.catch {_ in
                let result: NSMutableDictionary = [:]
                result["address"] = ""
                result["balance"] = ""
                callback(result)
            }
//        env.service.resolveTokenAccounts(accountId: KinAccount.Id(account["publicKey"] as! String)).then { accounts in
//            callback(accounts.map {
//                let result: NSMutableDictionary = [:]
//                result["address"] = $0.accountId
//                result["balance"] = $0.b
//                result
//            })
//        }
    }
    
}
