//
//  RealmWrapper.swift
//  MachoFramework
//
//  Created by 佐藤汰一 on 2024/11/30.
//

import CocoonCore
import Combine
import RealmSwift

@RealmActor
public struct RealmWrapper {
    
    private let realm: Realm
    
    // MARK: - RealmActor initialize method
    
    init(_ realm: Realm) {
        
        self.realm = realm
    }
    
    // MARK: - RealmActor public methods
    
    /// 任意のデータをRealmDBから取得する
    ///   - type: 取得したいデータの型
    /// - Returns: 引数で指定したデータ型のレコード配列を返す
    public func read<T>() -> [T] where T: BaseRealmEntity {
        
        let result = realm.objects(T.RealmObject.self)
        return toUnManagedObject(result)
    }
    
    /// RealmDBにデータを保存する
    /// - Parameter records: 保存したいデータの配列
    /// 重複したレコードが存在する場合は更新する
    public func insert<T>(records: [T]) async -> Bool where T: BaseRealmEntity {
        
        let realmRecords = records.map { $0.toRealmObject() }
        return await executeAsyncWrite { [realm = self.realm] in
            
            realmRecords.forEach { realm.add($0, update: .modified) }
        }
    }
    
    /// RealmDBに指定したレコードのカラムを非同期で更新する
    /// - Parameters:
    ///   - type: 更新するデータの型
    ///   - value: 更新するデータの主キーと更新したいカラムをDictionary型で指定する
    /// 重複したレコードが存在する場合は更新する
    public func update<T>(type: T.Type, value: [String: Any]) async -> Bool where T: BaseRealmEntity {
        
        return await executeAsyncWrite { [realm = self.realm] in
            
            realm.create(type.RealmObject, value: value, update: .modified)
        }
    }
    
    /// RealmDBに保存しているデータを非同期で削除
    /// - Parameter records: 削除したいレコードの配列
    /// - Parameter filterHandler: 削除するレコードの条件
    /// - Returns: 削除が成功したかどうか
    public func delete<T>(where filterHandler: @escaping (T) -> Bool) async -> Bool where T: BaseRealmEntity {
        
        let targetRecords = realm.objects(T.RealmObject.self)
            .filter {
                
                filterHandler(T(realmObject: $0))
            }
        return await executeAsyncWrite { [realm = self.realm] in
            
            targetRecords.forEach { realm.delete($0) }
        }
    }
    
    /// 指定のテーブルのデータを全て削除
    /// - Parameter type: 削除するデータの型
    /// - Returns: 削除が成功したかどうか
    public func deleteAll<T>(type: T.Type) async -> Bool where T: BaseRealmEntity {
        
        let objects = self.realm.objects(type.RealmObject.self)
        return await executeAsyncWrite { [realm] in
            
            realm.delete(objects)
        }
    }
    
    /// RealmDBに保存しているすべてのデータを削除
    public func truncateDb() async -> Bool {
        
        return await executeAsyncWrite { [realm = self.realm] in
            
            realm.deleteAll()
        }
    }
    
    /// 任意のデータタイプのRealmDBの変更を検知を監視を開始する
    /// - Parameters:
    ///   - type: 監視するデータタイプ
    ///   - updateHandler: 変更したRealmデータをStructとして通知するコールバックハンドラ
    /// - Returns: 監視のSubscribeを制御するToken
    public func readObjectsForObserve<T>(type: T.Type) async -> AnyPublisher<[T], Never>
    where T: BaseRealmEntity {
        
        let publisher = RealmObservePublisher<[T]>()
        let token = await realm.objects(type.RealmObject)
            .observe(on: RealmActor.shared) { _, snapshot in
                                
                switch snapshot {
                    
                case .initial(let initial):
                    publisher.send(toUnManagedObject(initial))
                    
                case .update(let update, _, _, _):
                    publisher.send(toUnManagedObject(update))
                    
                case .error(let error):
                    print("Occurred realm observe error: \(error), type: \(type)")
                }
            }
        
        publisher.setToken(token)
        return publisher.eraseToAnyPublisher()
    }
}

// MARK: - RealmActor private methods

private extension RealmWrapper {
    
    func executeAsyncWrite(_ operation: @escaping () -> Void) async -> Bool {
        
        return await withCheckedContinuation { continuation in
            
            realm.writeAsync(operation) { error in
                
                guard let error else {
                    
                    continuation.resume(returning: true)
                    return
                }
                
                print("Failed realm operation: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
    
    /// Realmオブジェクトの結果をStructの型に変換する
    /// - Parameter results: Realmから取得したResultオブジェクト
    /// - Returns: Resultオブジェクトに対応するStructの配列を返す
    nonisolated func toUnManagedObject<T>(_ results: Results<T.RealmObject>) -> [T] where T: BaseRealmEntity {
        
        return Array(results).map { T(realmObject: $0) }
    }
}
