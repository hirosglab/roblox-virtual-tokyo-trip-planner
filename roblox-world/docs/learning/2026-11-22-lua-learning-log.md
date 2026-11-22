# Roblox Lua Learning & Development Log

Luaの基本文法と開発知見の整理ログです。

## 📌 該当コード

    local boardsFolder = workspace:WaitForChild("Featured_Sightseeing_Spots_Boards", 10)
    local board = boardsFolder and boardsFolder:WaitForChild("InfoBoard_13_TsukijiOuterMarket", 10)

    if not board then
        warn("InfoBoard_13_TsukijiOuterMarket が Featured_Sightseeing_Spots_Boards 内で見つかりません")
        return
    end

## 🔍 構成要素の詳細説明

### 1. 論理演算子 `and` と文字列結合 `..` の違い
Lua における `and` は文字列をくっつける演算子ではなく、**論理演算子**として動作します。

- **論理演算 `and` の挙動**: 左側の値が偽（`nil` または `false`）でない場合、右側の式を評価してその結果を返します。`boardsFolder` が `nil` の場合は右側の `:WaitForChild(...)` を呼ばずにスキップし、`nil` にインデックスアクセスしてエラーになるのを防ぎます。
- **文字列結合 `..`（ドット2つ）**: Lua で文字列同士を連結したい場合は `and` ではなく `..` を使用します。例えば `"A" .. " & " .. "B"` と書くことで `"A & B"` という文字列になります。
- **1行連結書きとの比較**: `workspace:WaitForChild(...):WaitForChild(...)` のように1行で繋ぐことも可能ですが、親フォルダーが見つからなかった場合に `nil` に対してメソッド呼び出しエラーが起きやすいため、段階的に確認する書き方の方が堅牢です。

## 📌 該当コード

    local audioFolder = workspace:WaitForChild("AudioAssets", 10)
    local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)

    if popSound then
        popSound.SoundId = "rbxassetid://100517105966579"
        popSound.Volume = 0.8
        popSound.RollOffMaxDistance = 50
    end

    local function playPopSound()
        if popSound then
            popSound.TimePosition = 0
            popSound:Play()
        end
    end

## 🔍 構成要素の詳細説明

### 1. `Sound` インスタンスの取得とプロパティ設定・再生
`WaitForChild` で取得できるのは名前ではなく `Sound` インスタンス本体です。

- **プロパティによる制御**: `SoundId`、`Volume`、`RollOffMaxDistance` はスクリプトから明示的に代入することで、Studio 側の設定漏れや上書きを防ぎ、意図した音声パラメータを保証できます。Studio 側に正しく設定されていれば、スクリプトでの `SoundId` 代入を省いても `popSound:Play()` は動作します。
- **誤った `SoundId` を指定した場合**: スクリプト全体がエラーで即座に停止することは少なく、無効・非公開・形式ミスや別種アセットの場合は無音（Output にロード失敗の警告）になり、たまたま存在する別アセットの ID と一致した場合はその別の音が再生されます。
- **再生位置のリセット**: `popSound.TimePosition = 0` を指定してから `popSound:Play()` を呼ぶことで、連続トリガー時でも頭出しから効果音を再生できます。

## 📌 該当コード

    local allProps = {
        p_Toro1, p_Tamago1, p_Salmon1,
        p_Toro2, p_Tamago2, p_Salmon2,
        p_Toro3, p_Tamago3, p_Salmon3,
        p_Toro4, p_Tamago4, p_Salmon4
    }

    local originalData = {}

    for _, prop in ipairs(allProps) do
        if prop then
            if prop:IsA("Model") then
                originalData[prop] = {
                    Scale = prop:GetScale(),
                    CFrame = prop:GetPivot()
                }
            elseif prop:IsA("BasePart") then
                originalData[prop] = {
                    Size = prop.Size,
                    CFrame = prop.CFrame
                }
            end
        end
    end

## 🔍 構成要素の詳細説明

### 1. `Model` と `BasePart` の型判定と初期値記録
オブジェクトが `Model` か `BasePart`（`MeshPart` や `Part` など）かによって、位置・サイズ／スケールを扱う API が異なるため `prop:IsA(...)` で切り分けています[cite: 3]。

- **`Model` の場合**: 複数パーツのまとまり（コンテナ）であり、単体パーツのような `.Size` や `.CFrame` プロパティを持たないため、`:GetScale()` と `:GetPivot()` でモデル全体の拡大率と基準位置・向きを取得します。たとえば `Prop_Sushi_Salmon_01` が `Model` で配下に `Sushi_Rice` や `Sushi_Salmon`（`MeshPart`）を持つ場合も `Model` として判定され、モデル全体の `Scale` と `CFrame` が記録されます[cite: 3]。
- **`BasePart` の場合**: 単一の立体パーツであるため、`prop.Size` と `prop.CFrame` を直接読み取って保存します。

## 📊 学習ポイントまとめ表

| 学習テーマ | 対象要素 / 構文 | 主な役割・ポイント |
| :--- | :--- | :--- |
| 論理演算と文字列結合 | `and` / `..` | `and` は条件評価（nilガードに活用）、`..` は文字列結合 |
| サウンドインスタンス制御 | `Sound` / `SoundId` / `TimePosition` / `Play()` | Studio設定の補強と頭出し再生、誤ID時は警告または別音再生 |
| 3Dオブジェクト型分岐 | `IsA("Model")` / `IsA("BasePart")` | 複数パーツ群は `GetScale()`・`GetPivot()`、単体パーツは `Size`・`CFrame` |
