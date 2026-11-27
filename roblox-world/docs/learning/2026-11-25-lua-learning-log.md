# Roblox Lua Learning & Development Log

ポップアップアニメーションにおける Model 側の処理（CFrame 合成、Heartbeat ループ、イージング補間、接続解除）に関する整理ログです。

## 📌 該当コード

    if prop:IsA("Model") then
        local origCF = originalData[prop].CFrame
        local origScale = originalData[prop].Scale

        local startCF = origCF * CFrame.new(0, -1.5, 0)
        prop:PivotTo(startCF)
        prop:ScaleTo(origScale * 0.2)

        local startTime = os.clock()

        local conn
        conn = RunService.Heartbeat:Connect(function()
            local elapsed = os.clock() - startTime
            local alpha = math.clamp(elapsed / TWEEN_TIME, 0, 1)

            local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            local currentScale = (origScale * 0.2) + (origScale * 0.8) * easedAlpha
            local currentCF = startCF:Lerp(origCF, easedAlpha)

            prop:ScaleTo(currentScale)
            prop:PivotTo(currentCF)

            if alpha >= 1 then
                conn:Disconnect()
                prop:ScaleTo(origScale)
                prop:PivotTo(origCF)
            end
        end)

## 🔍 構成要素の詳細説明

### 1. `CFrame.new(0, -1.5, 0)` と `*` 演算子の意味（Lua の構文と Roblox 固有仕様の切り分け）
`origCF * CFrame.new(0, -1.5, 0)` は、数値の掛け算ではなく、**`CFrame`（位置と向きのセット）同士を合成して新しい座標・向きを作る処理**です。

- **Lua 言語側の役割**: `local` による変数宣言、関数呼び出し、二項演算子 `*` を使う構文の枠組み自体は Lua の文法です。
- **Roblox 固有の役割**: `CFrame` 型、`CFrame.new(0, -1.5, 0)` コンストラクタ、および `CFrame * CFrame` による変換の重ね合わせルールは Roblox エンジン独自の仕様です（素の Lua には存在しません）。
- **開始位置とスケールの設定**: `origCF` から Y 方向に -1.5 Studs ずらした `startCF` を計算し、`prop:PivotTo(startCF)` と `prop:ScaleTo(origScale * 0.2)` で「少し下かつ 0.2 倍に縮小した開始状態」を作ります。

### 2. `local conn` と `conn = RunService.Heartbeat:Connect(...)` の分離と入れ子構造
`animatePopIn(prop)` はシーケンス関数などから呼ばれ、内部で `RunService.Heartbeat:Connect(function() ... end)` を使ってその Model 1つ分のアニメーションを毎フレーム更新します。

- **2行に分ける理由**: 先に `local conn` で変数を宣言してから `conn = ...` と代入することで、コールバック関数内部の `if alpha >= 1 then conn:Disconnect() end` から自分自身の接続オブジェクトを安全に参照・解除できるようにしています。
- **実行の流れと後片付け**: `os.clock()` で開始時刻を記録した後、毎フレーム `elapsed` と `alpha`（0〜1 にクランプ）を計算し、`alpha >= 1` になったら `conn:Disconnect()` で接続を解除し、`prop:ScaleTo(origScale)` と `prop:PivotTo(origCF)` で本来の値に確定させます。

### 3. `TweenService:GetValue(...)` と `TweenInfo.new(...)` の役割の違い
`popTweenInfo`（`TweenInfo.new(...)`）は `TweenService:Create` に渡す設定オブジェクトであり、`TweenService:GetValue(...)` は手計算ループの中でイージング適用後の数値（`easedAlpha`）だけを受け取る関数です。

- **再定義ではない理由**: `TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)` は `popTweenInfo` を上書きするのではなく、進捗率 `alpha` に `Back` / `Out` のカーブを適用した補間値を返します。
- **スケールと位置の補間**: 得られた `easedAlpha` を使い、`currentScale = (origScale * 0.2) + (origScale * 0.8) * easedAlpha` と `currentCF = startCF:Lerp(origCF, easedAlpha)` を毎フレーム算出して `prop:ScaleTo(...)` と `prop:PivotTo(...)` に反映します。

## 📊 学習ポイントまとめ表

| 学習テーマ | 対象要素 / 構文 | 主な役割・ポイント |
| :--- | :--- | :--- |
| 3D 変換の合成 | `CFrame.new(0, -1.5, 0)` / `*` / `:PivotTo()` / `:ScaleTo()` | 構文は Lua だが CFrame 型と合成仕様は Roblox 固有であり、開始位置・初期縮小状態を設定する |
| 接続解除とループ制御 | `local conn` / `RunService.Heartbeat:Connect` / `os.clock()` / `conn:Disconnect()` | コールバック内から自身を解除するために事前宣言し、完了時に解除して初期値へ確定する |
| イージング補間値の算出 | `TweenService:GetValue` / `math.clamp` / `:Lerp()` | popTweenInfo の再定義ではなく、毎フレームの進捗 alpha から Back.Out の補間値を計算して適用する |
