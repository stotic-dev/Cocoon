# Cocoon

Realm のスレッドセーフ問題を解決するためのライブラリです。Realm オブジェクトは通常スレッドを跨げないため、非同期処理が絡む並列プログラミングでは使用しづらい問題があります。

Cocoon では、Realm オブジェクトと同じ構造の Sendable な型を用意し、スレッドを跨ぐ際は Sendable な型にコンバートして使用する手法を、マクロと Actor でサポートします。

## 設計思想

### 問題

Realm のオブジェクトは通常スレッドを跨げないため、非同期処理が絡む並列プログラミングでは使用しづらいケースが多々あります。

### 解決アプローチ

1. **Sendable な型の導入**: Realm オブジェクトと同じ構造の Sendable な型を用意
2. **スレッド間での型変換**: スレッドを跨ぐ際は Sendable な型にコンバート
3. **マクロによる自動生成**: 変換処理をマクロで自動生成
4. **Actor によるラップ**: RealmWrapper で全ての Realm 操作をラップし、スレッドセーフ問題を吸収

## 要件

- macOS 10.15+ / iOS 17.0+
- Swift 6.1 以上

## インストール

### Swift Package Manager

`Package.swift`に以下の依存関係を追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/stotic-dev/Cocoon.git", branch: "main")
]
```

## 主要機能

### マクロ

- **`@Object`**: RealmObject の定義
- **`@ObjectEntity`**: Entity 構造体の定義
- **`@ObjectMember`**: ネストしたオブジェクトの定義

### スレッドセーフな操作

- **`RealmWrapper`**: CRUD 操作のラッパー
- **`RealmFactory`**: Realm インスタンスの作成

## 基本的な使用方法

### 1. RealmObject の定義

まず、従来の RealmObject を定義します。ここで定義した型に`@Object`マクロを付与します。

```swift
import Cocoon
import RealmSwift

@Object
final class MessageObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var message: String
}
```

### 2. Entity 構造体の定義

次に、スレッドを跨げる Sendable な Entity 構造体を定義します。`@ObjectEntity`マクロにより、RealmObject と Entity 間の変換処理が自動生成されます。

```swift
@ObjectEntity(MessageObject.self)
struct MessageObjectEntity: Sendable {
    let id: UUID
    let message: String
}
```

この Entity 構造体は：

- **Sendable**: スレッド間で安全に受け渡し可能
- **自動変換**: RealmObject との相互変換がマクロで自動生成
- **型安全**: コンパイル時に型チェックが行われる

### 3. RealmWrapper の初期化

`RealmFactory`を使用してスレッドセーフな Realm インスタンスを作成します。`@RealmActor`により、すべての操作が専用の Actor 内で実行されます。

```swift
import Cocoon

final class RealmStore: Sendable {
    static let shared = RealmStore()

    private let realm: Task<RealmWrapper, Error>

    init() {
        let dir = URL.applicationSupportDirectory
        // RealmFactoryによりスレッドセーフなRealmインスタンスを作成
        realm = RealmFactory.create(url: dir.appending(path: "db.realm"), version: 1)
    }

    func getRealm() -> Task<RealmWrapper, Never> {
        return Task {
            do {
                // @RealmActor内でRealmWrapperを取得
                return try await realm.value
            } catch {
                preconditionFailure("Failed create realm: \(error)")
            }
        }
    }
}
```

実際どのように CRUD 処理を実装するのかについては、[サンプルプロジェクト](Example/CocoonExample)を確認してください。

## 注意事項

- すべての Realm 操作は`@RealmActor`内で実行されます
- Entity 構造体は`BaseRealmEntity`プロトコルに準拠する必要があります

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 貢献

プルリクエストやイシューの報告を歓迎します。貢献する前に、まずイシューを開いて変更内容について議論してください。
