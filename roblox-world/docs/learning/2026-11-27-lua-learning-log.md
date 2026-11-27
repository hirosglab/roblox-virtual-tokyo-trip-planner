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

## 📐 参考：コーディングに必要な数学的理解の背景

本プログラムはコーディング学習が主軸ですが、ベクトル演算や内積のコード（`Vector3:Dot`）が意図通りに動作する背景には以下の数学的・幾何学的概念が存在します。

### 1. 内積（Dot Product）と角度の対応関係
長さ `1` に正規化（`.Unit`）した2つの単位ベクトル間の内積は、2つのベクトルのなす角 $\theta$（シータ）の三角関数 `cos(θ)` と等しくなります。

- **正面（θ = 0°）**: `cos(0°) = 1.0` （完全な正面）
- **検知境界（θ ≒ 25.8°）**: `cos(25.8°) ≒ 0.9` （しきい値 `0.9` の範囲）
- **真横（θ = 90°）**: `cos(90°) = 0.0` （直交）
- **真後ろ（θ = 180°）**: `cos(180°) = -1.0` （逆向き）
```
    [内積値（dot）と視野角の概念図]
                  看板の正面 (boardForward)
                           ↑  θ = 0°  →  dot = 1.00
                      \    |    /
                       \   |   /   ← dot > 0.90（約 ±25.8° 以内）
                        \  |  /
     θ = -90° (0.0) ← ----●---- → θ = +90° (0.0)
                        看板(boardPos)
                           ↓  θ = ±180° →  dot = -1.00（裏側）
```
### 2. 角度 θ・内積（dot）・判定結果の対応表

| プレイヤーの位置関係（看板から見た方向） | 角度差 θ の目安 | 内積 dot（=cosθ） | dot > 0.9 の判定 | ゲーム上の挙動イメージ |
| :--- | :---: | :---: | :---: | :--- |
| 完全に正面 | 0° | 1.00 | true | 真正面から看板を見ている状態 |
| 正面のやや斜め（検知内） | 約 18° | 約 0.95 | true | 0.9 より大きいため反応する |
| 検知境界付近 | 約 25.8° | 0.90 | false（> のため） | この内側（> 0.9）で反応し、外で反応しない |
| 斜め前〜横寄り（検知外） | 45° | 約 0.71 | false | 隣の看板と誤反応しやすい角度だが除外される |
| 真横 | 90° | 0.00 | false | 看板の側面方向 |
| 斜め後ろ・真後ろ | 135° 〜 180° | -0.71 〜 -1.00 | false | 看板の裏側方向 |

### 3. しきい値（0.9）を変えたときの感覚の違い

| しきい値の設定 | 角度 θ の目安（片側） | 判定エリアの幅 | 向いている用途 |
| :--- | :---: | :--- | :--- |
| dot > 0.95 | 約 18° | かなり狭い | 真正面に立ったときだけピンポイントで反応させたい場合 |
| dot > 0.9（現在） | 約 25.8° | やや狭い | 離れた位置から隣の看板への誤反応を抑えたい場合 |
| dot > 0.8 | 約 36.9° | 中くらい | 少し斜めから近づいても反応させたい場合 |
| dot > 0.5 | 60° | 広い（前半分に近い） | 看板の広い前面エリア全体で反応させたい場合 |

数値を 0.9 から小さくするほど「反応する角度（扇形の開き）」が広がり、大きくするほど「真正面限定」に絞られます。
  
## 📊 学習ポイントまとめ表

| 学習テーマ | 対象要素 / 構文 | 主な役割・ポイント |
| :--- | :--- | :--- |
| 距離と方向ベクトル | `(hrp.Position - boardPos).Magnitude` / `toPlayer` | 引き算で看板からプレイヤーへの矢印ベクトルを作り、Magnitude で直線距離を得る |
| 水平面射影と正規化 | `Vector3.new(x, 0, z)` / `.Unit` / `Magnitude == 0` | 高低差を除外して長さを 1.0 に揃え、ゼロベクトルを除外して安全に向きを取り出す |
| 内積による角度判定 | `boardForward:Dot(toPlayer)` / `dot > 0.9` | 単位ベクトルの内積から cos(θ) を求め、正面の狭い視野角（約25度以内）を判定する |
