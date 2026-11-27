# Roblox Lua Learning & Development Log

プレイヤーと看板の距離および前方視野角（内積）を判定する checkPlayerInFront 関数の整理ログです。

## 📌 該当コード

    local function checkPlayerInFront()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local boardPivot = board:GetPivot()
            local boardPos = boardPivot.Position

            local dist = (hrp.Position - boardPos).Magnitude
            if dist > TRIGGER_DISTANCE then
                return false
            end

            if dist <= 15 then
                return true
            end

            local boardForward = -boardPivot.LookVector
            local toPlayer = (hrp.Position - boardPos)

            toPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
            boardForward = Vector3.new(boardForward.X, 0, boardForward.Z)

            if toPlayer.Magnitude == 0 or boardForward.Magnitude == 0 then
                return false
            end

            toPlayer = toPlayer.Unit
            boardForward = boardForward.Unit

            local dot = boardForward:Dot(toPlayer)

            return dot > 0.9
        end
        return false
    end

## 🔍 構成要素の詳細説明

### 1. 距離の算出とベクトル（矢印データ）の違い
`hrp.Position - boardPos` は看板の位置を始点とし、プレイヤーの位置を終点とする**ベクトル（向きと大きさを持つ矢印データ）**を生成します。

- **直線距離（`.Magnitude`）**: `local dist = (hrp.Position - boardPos).Magnitude` でベクトルの長さを取り出し、2点間の直線距離を Studs 単位で求めます。
- **方向ベクトル（`toPlayer`）**: `local toPlayer = (hrp.Position - boardPos)` は距離だけでなく「看板から見てプレイヤーがどの方向にあるか」を示す矢印として、角度判定の前処理に使います。
- **段階的な距離フィルタ**: `dist > TRIGGER_DISTANCE` なら即座に `false` を返し、`dist <= 15` の至近距離では視点移動で急に表示が消えないよう `true` を返します。

### 2. 前処理（XZ平面への射影と正規化）
角度を正確に測るため、`boardForward` と `toPlayer` の両方に同じ前処理を適用します。

- **XZ平面への射影**: `Vector3.new(v.X, 0, v.Z)` として Y 軸（高低差）を 0 にし、真上から見た水平方向だけの向きに絞ります。
- **ゼロベクトルガード**: `Magnitude == 0` の場合は正規化で 0 除算（NaN）が起きるのを防ぐため `false` を返します。
- **正規化（`.Unit`）**: 丸め込みではなく、向きを維持したまま長さを `1.0` の単位ベクトルへ変換し、距離の影響をなくして純粋な向きだけにします。

### 3. 内積（`:Dot(...)`）による前方視野角の判定
正規化済みの2つの単位ベクトルに対して `local dot = boardForward:Dot(toPlayer)` を呼び出し、向きの近さを数値化します。

- **内積の意味**: 長さ 1 の単位ベクトル同士の内積は `cos(θ)`（2つの向きのなす角度のコサイン）に一致し、`dot = (boardForward.X * toPlayer.X) + (boardForward.Z * toPlayer.Z)` のように計算されます。
- **しきい値 `dot > 0.9`**: 完全に正面なら `1.0`、約 90 度の横方向なら `0.0`、裏側なら負の値になります。`dot > 0.9`（角度にして約 25 度以内）とすることで、離れた位置から隣の看板へ誤反応するのを防ぎます。

## 📊 学習ポイントまとめ表

| 学習テーマ | 対象要素 / 構文 | 主な役割・ポイント |
| :--- | :--- | :--- |
| 距離と方向ベクトル | `(hrp.Position - boardPos).Magnitude` / `toPlayer` | 引き算で看板からプレイヤーへの矢印ベクトルを作り、Magnitude で直線距離を得る |
| 水平面射影と正規化 | `Vector3.new(x, 0, z)` / `.Unit` / `Magnitude == 0` | 高低差を除外して長さを 1.0 に揃え、ゼロベクトルを除外して安全に向きを取り出す |
| 内積による角度判定 | `boardForward:Dot(toPlayer)` / `dot > 0.9` | 単位ベクトルの内積から cos(θ) を求め、正面の狭い視野角（約25度以内）を判定する |
