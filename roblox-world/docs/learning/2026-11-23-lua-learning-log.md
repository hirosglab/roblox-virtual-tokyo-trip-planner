# Roblox Lua Learning & Development Log

MeshPart と BasePart の継承関係、および Lua スクリプトの構成順序に関する整理ログです。

## 📌 該当コード

    local function setPropTransparency(prop, transparency)
        if not prop then return end

        if prop:IsA("BasePart") then
            prop.Transparency = transparency
        elseif prop:IsA("Model") then
            for _, child in ipairs(prop:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.Transparency = transparency
                end
            end
        end
    end

## 🔍 構成要素の詳細説明

### 1. `MeshPart` は `BasePart` を継承している
Roblox のクラス階層において、`MeshPart` は `BasePart` を継承したサブクラス（`BasePart` の一種）です。

- **`:IsA("BasePart")` の判定結果**: `MeshPart` に対して `:IsA("BasePart")` を呼ぶと `true` が返ります。`Part` や `WedgePart` などと同様に、`Transparency`、`CFrame`、`Size` といった `BasePart` 共通のプロパティを扱えます。
- **子孫要素の一括制御**: `Prop_Sushi_Salmon_01` のような `Model` 自体には `Transparency` プロパティがないため、`:GetDescendants()` で配下の `Sushi_Rice` や `Sushi_Salmon` などの子要素をたどり、`child:IsA("BasePart")` で絞り込んだうえで `Transparency` を変更します。`BasePart` 以外の要素が混ざっていてもエラーを防げます。

## 📌 該当コード

    -- 1. オブジェクト・サービス・アセットの参照
    local RunService = game:GetService("RunService")

    -- 2. 初期化処理に必要な local function の定義
    local function hideAllSushi()
        -- 初期非表示などの処理
    end

    -- 3. 初期処理の実行
    hideAllSushi()

    -- 4. イベント発生時に必要な local function の定義
    local function showProp(prop)
        -- ポップアップ演出や効果音再生などの処理
    end

    -- 5. イベント発生時の処理（毎フレーム判定など）
    RunService.Heartbeat:Connect(function()
        -- 条件を満たしたときに showProp(...) などを呼び出す
    end)

## 🔍 構成要素の詳細説明

### 1. Lua におけるスクリプトの構成順と実行の流れ
Lua は原則としてコードの上から下へ逐次評価されるため、「呼び出す前に定義する」流れに沿った構造が自然で安全です。

- **基本の構成順**: オブジェクト・サービスの呼び込み → 初期化に必要な `local function` の定義 → 初期処理の実行 → イベント発生時に必要な `local function` の定義 → イベント発生時の処理（`:Connect(...)` など）の順で組み立てます。
- **初期実行とイベントループの役割分担**: 最初に `hideAllSushi()` などの初期処理を1回実行して状態を揃え、その後に `RunService.Heartbeat:Connect(function() ... end)` のような繰り返しイベントのコールバック内から、必要な `local function` を呼び出す形になります。
- **共通ヘルパーや定数の配置**: 初期化とイベント処理の両方から使われる関数や定数・テーブルは、参照される箇所より前にまとめて配置しておくと重複や参照順のミスを防げます。

## 📊 学習ポイントまとめ表

| 学習テーマ | 対象要素 / 構文 | 主な役割・ポイント |
| :--- | :--- | :--- |
| クラス継承と型判定 | `MeshPart` / `BasePart` / `IsA("BasePart")` / `GetDescendants()` | MeshPart は BasePart の一種であり、Model 配下の子孫パーツを絞り込んで一括操作できる |
| Lua スクリプト構造 | `local function` / 初期実行 / `RunService.Heartbeat:Connect` | 上から順に定義・初期化した後、イベントコールバック内からローカル関数を呼び出す |
