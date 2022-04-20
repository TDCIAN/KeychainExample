//
//  ViewController.swift
//  KeychainExample
//
//  Created by JeongminKim on 2022/04/20.
//

import UIKit

class ViewController: UIViewController {
    
    let account = UIDevice.current.name
    let service = Bundle.main.bundleIdentifier ?? ""

    override func viewDidLoad() {
        super.viewDidLoad()
        deletePassword()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        savePassword()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getPassword()
    }

    func savePassword() {
        do {
            try KeychainManager.save(
                service: service,
                account: account,
                password: "AnotherOne".data(using: .utf8) ?? Data()
            )
        } catch {
            print(error)
        }
    }

    func getPassword() {
        guard let data = KeychainManager.get(
            service: service,
            account: account
        ) else {
            print("Failed to read password")
            return
        }
        
        let password = String(decoding: data, as: UTF8.self)
        print("Read password: \(password)")
    }
    
    func deletePassword() {
        guard let data = KeychainManager.get(
            service: service,
            account: account
        ) else {
            print("Failed to read password - no password")
            return
        }
        KeychainManager.delete(service: service, account: account, password: data)
    }
}

class KeychainManager {
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
    }
    
    static func save(service: String, account: String, password: Data) throws {
        // service, account, password, class, data
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword, // 키체인 아이템 클래스 타입
            kSecAttrService as String: service as AnyObject, // 서비스 아이디 -> 앱 번들 아이디
            kSecAttrAccount as String: account as AnyObject, // 저장할 아이템의 계정 이름
            kSecValueData as String: password as AnyObject // 저장할 아이템의 데이터
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil) // 키체인에 하나 이상의 항목을 추가할 때 사용
        guard status != errSecDuplicateItem  else {
            throw KeychainError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
        
        print("save - status: \(status)")
    }
    
    static func get(service: String, account: String) -> Data? {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        // 검색 쿼리와 일치하는 키체인 항목을 하나 이상 반환하는 기능, 특정 키 체인 항목의 속성을 복사할 수 있음
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )
        
        print("get - status: \(status)")
        
        return result as? Data
    }
    
    static func delete(service: String, account: String, password: Data) {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword, // 키체인 아이템 클래스 타입
            kSecAttrService as String: service as AnyObject, // 서비스 아이디 -> 앱 번들 아이디
            kSecAttrAccount as String: account as AnyObject, // 저장할 아이템의 계정 이름
            kSecValueData as String: password as AnyObject // 저장할 아이템의 데이터
        ]
        let passwordToDelete = String(decoding: password, as: UTF8.self)
        print("passwordToDelete - \(passwordToDelete)")
        let status = SecItemDelete(query as CFDictionary)
        print("delete - status: \(status)")
    }
}
