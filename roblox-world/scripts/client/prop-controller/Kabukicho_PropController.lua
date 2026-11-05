-- ============================================================
-- 歌舞伎町：恐竜プロップ落下演出スクリプト（Head_Lower指定・煙強調版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ------------------------------------------------------------
-- 1. サウンドの参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
if not audioFolder then
	local propsFolder = workspace:FindFirstChild("Props")
	if propsFolder then
		audioFolder = propsFolder:FindFirstChild("AudioAssets")
	end
end

local screamSound = audioFolder and audioFolder:WaitForChild("SE_Kaijyu Scream", 10)
local boomSound = audioFolder and audioFolder:WaitForChild("SE_BOOM-Thump", 10)

if screamSound then
	screamSound.Volume = 0.2
	screamSound.RollOffMaxDistance = 50
end

if boomSound then
	boomSound.Volume = 0.8
	boomSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > Kabukicho フォルダから Prop_Dinosaur を取得
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local kabukichoFolder = propsFolder and propsFolder:WaitForChild("Kabukicho", 10)

if not kabukichoFolder then
	warn("Props/Kabukicho フォルダが見つかりません")
	return
end

local dinosaur = kabukichoFolder:WaitForChild("Prop_Dinosaur", 10)
if not dinosaur then
	warn("Prop_Dinosaur が見つかりませんでした")
	return
end

-- ------------------------------------------------------------
-- ★ 恐竜（モデル）の本来の位置（CFrame）を記録
-- ------------------------------------------------------------
local originalPivot = nil
if dinosaur:IsA("Model") then
	originalPivot = dinosaur:GetPivot()
elseif dinosaur:IsA("BasePart") then
	originalPivot = dinosaur.CFrame
end

-- ------------------------------------------------------------
-- 煙（Smoke）エフェクトを Head_Lower に直接アタッチ（読み込み待機版）
-- ------------------------------------------------------------
local smokeEffect = nil
local targetPart = nil

if dinosaur:IsA("Model") then
	-- FindFirstChild から WaitForChild に変更し、パーツが読み込まれるのを最大5秒待機します
	targetPart = dinosaur:WaitForChild("Head_Lower", 5)
elseif dinosaur:IsA("BasePart") then
	targetPart = dinosaur
end

if targetPart then
	smokeEffect = Instance.new("Smoke")
	smokeEffect.Size = 5         -- 煙の大きさ
	smokeEffect.RiseVelocity = 6   -- 上昇スピード
	smokeEffect.Opacity = 0.9      -- 不透明度（濃さ）
	smokeEffect.Color = Color3.fromRGB(230, 230, 230) -- 色
	smokeEffect.Enabled = false
	smokeEffect.Parent = targetPart
else
	warn("Head_Lower が見つからなかったため、煙エフェクトは作成されませんでした")
end

-- ------------------------------------------------------------
-- 補助関数：透明度とアンカーの設定
-- ------------------------------------------------------------
local function setDinosaurVisible(target, visible)
	local transparency = visible and 0 or 1
	if target:IsA("BasePart") then
		target.Transparency = transparency
		target.CanCollide = visible
	elseif target:IsA("Model") then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = transparency
				child.CanCollide = visible
			end
		end
	end
end

local function setDinosaurAnchored(target, anchored)
	if target:IsA("BasePart") then
		target.Anchored = anchored
	elseif target:IsA("Model") then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Anchored = anchored
			end
		end
	end
end

-- 初期化処理（開始時は非表示＆アンカーオン）
setDinosaurVisible(dinosaur, false)
setDinosaurAnchored(dinosaur, true)
if originalPivot and dinosaur:IsA("Model") then
	dinosaur:PivotTo(originalPivot)
end

-- ------------------------------------------------------------
-- 検知エリアの範囲定義（指定された4つの座標をカバーする直方体）
-- X: -103 ～ -65 / Z: -38 ～ -10
-- ------------------------------------------------------------
local minX, maxX = -103, -65
local minZ, maxZ = -38, -10

local function isPlayerInZone(position)
	return position.X >= minX and position.X <= maxX 
		and position.Z >= minZ and position.Z <= maxZ
end

-- 状態管理フラグ
local isInside = false
local activeAnim = nil

-- ------------------------------------------------------------
-- 上空から落ちてくる演出アニメーション
-- ------------------------------------------------------------
local function playDropAnimation()
	if not originalPivot then return end

	-- 1. 表示の前に SE_Kaijyu Scream を鳴らす
	if screamSound then
		screamSound.TimePosition = 0
		screamSound:Play()
	end

	-- 2. 可視化してアンカーをオン
	setDinosaurVisible(dinosaur, true)
	setDinosaurAnchored(dinosaur, true)
	if smokeEffect then smokeEffect.Enabled = false end

	-- 3. 本来の位置より上空（Y軸 + 15 studs）からスタートさせる
	local dropHeight = 15
	local startPivot = originalPivot + Vector3.new(0, dropHeight, 0)
	dinosaur:PivotTo(startPivot)

	-- 4. 落下アニメーションの実行 (TweenService)
	local dropDuration = 1.2 
	local startTime = os.clock()

	if activeAnim then activeAnim:Disconnect() end

	activeAnim = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / dropDuration, 0, 1)

		local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local currentPivot = startPivot:Lerp(originalPivot, easedAlpha)
		dinosaur:PivotTo(currentPivot)

		if alpha >= 1 then
			if activeAnim then
				activeAnim:Disconnect()
				activeAnim = nil
			end
			dinosaur:PivotTo(originalPivot)

			-- 5. 地面にドンと着地した瞬間に SE_BOOM-Thump を鳴らし、煙を発生させる
			if boomSound then
				boomSound.TimePosition = 0
				boomSound:Play()
			end

			if smokeEffect then
				smokeEffect.Enabled = true
				-- 1.5秒後に煙を消す
				task.delay(1.5, function()
					if smokeEffect then
						smokeEffect.Enabled = false
					end
				end)
			end
		end
	end)
end

-- ------------------------------------------------------------
-- プレイヤーの位置監視ループ
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrpPos = char.HumanoidRootPart.Position
		local currentlyInside = isPlayerInZone(hrpPos)

		if currentlyInside and not isInside then
			-- エリアに進入した瞬間
			isInside = true
			playDropAnimation()

		elseif not currentlyInside and isInside then
			-- エリアから外れた瞬間
			isInside = false
			if activeAnim then
				activeAnim:Disconnect()
				activeAnim = nil
			end
			if smokeEffect then smokeEffect.Enabled = false end
			-- 非表示に戻し、位置を元に戻す
			setDinosaurVisible(dinosaur, false)
			setDinosaurAnchored(dinosaur, true)
			if originalPivot and dinosaur:IsA("Model") then
				dinosaur:PivotTo(originalPivot)
			end
		end
	end
end)
