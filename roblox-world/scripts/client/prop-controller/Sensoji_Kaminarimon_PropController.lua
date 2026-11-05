-- ============================================================
-- 浅草寺・雷門の提灯：時間差出現・湧き上がりスクリプト（検知範囲縮小版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ------------------------------------------------------------
-- 1. サウンド（SE_YO, SE_DEDEN）の参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
if not audioFolder then
	local propsFolder = workspace:FindFirstChild("Props")
	if propsFolder then
		audioFolder = propsFolder:FindFirstChild("AudioAssets")
	end
end

local soundYo = audioFolder and audioFolder:WaitForChild("SE_YO", 10)
local soundDeden = audioFolder and audioFolder:WaitForChild("SE_DEDEN", 10)

if soundYo then
	soundYo.Volume = 0.4
	soundYo.RollOffMaxDistance = 50
end

if soundDeden then
	soundDeden.Volume = 0.8
	soundDeden.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > Senso-ji フォルダから提灯プロップを取得
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local sensojiFolder = propsFolder and propsFolder:WaitForChild("Senso-ji", 10)

if not sensojiFolder then
	warn("Props/Senso-ji フォルダが見つかりません")
	return
end

local lantern = sensojiFolder:WaitForChild("Prop_Lantern_Kaminarimon", 10)
if not lantern then
	warn("Prop_Lantern_Kaminarimon が見つかりませんでした")
	return
end

-- ------------------------------------------------------------
-- ★ 提灯（モデル）の初期位置・スケールの記録
-- ------------------------------------------------------------
local originalData = {}

if lantern:IsA("Model") then
	originalData[lantern] = {
		Scale = lantern:GetScale(),
		CFrame = lantern:GetPivot()
	}
elseif lantern:IsA("BasePart") then
	originalData[lantern] = {
		Size = lantern.Size,
		CFrame = lantern.CFrame
	}
end

-- ------------------------------------------------------------
-- 透明度切り替え補助関数（モデル内の全パーツ対応）
-- ------------------------------------------------------------
local function setLanternTransparency(target, transparency)
	if not target then return end

	if target:IsA("BasePart") then
		target.Transparency = transparency
	elseif target:IsA("Model") then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = transparency
			end
		end
	end
end

-- ------------------------------------------------------------
-- 衝突判定（CanCollide）切り替え補助関数
-- ------------------------------------------------------------
local function setLanternCollision(target, canCollide)
	if not target then return end

	if target:IsA("BasePart") then
		target.CanCollide = canCollide
	elseif target:IsA("Model") then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("BasePart") then
				child.CanCollide = canCollide
			end
		end
	end
end

-- ------------------------------------------------------------
-- 非表示リセット処理
-- ------------------------------------------------------------
local function hideLantern()
	if lantern and originalData[lantern] then
		setLanternTransparency(lantern, 1)
		setLanternCollision(lantern, false)
		if lantern:IsA("Model") then
			lantern:PivotTo(originalData[lantern].CFrame)
			lantern:ScaleTo(originalData[lantern].Scale)
		end
	end
end

-- 初期化（開始時は非表示・衝突無効）
hideLantern()

-- ------------------------------------------------------------
-- 下からゆっくり湧き上がるアニメーション（Model対応版）
-- ------------------------------------------------------------
local ANIM_TIME = 1.2 -- 湧き上がりにかかる時間（秒）
local activeAnimConnection = nil

local function playRiseAnimation()
	-- 進行中のアニメーションがあれば切断
	if activeAnimConnection then
		activeAnimConnection:Disconnect()
		activeAnimConnection = nil
	end

	-- 1. 表示前に SE_YO を再生
	if soundYo then
		soundYo.TimePosition = 0
		soundYo:Play()
	end

	-- 2. 表示状態にしてコリジョンを有効化
	setLanternTransparency(lantern, 0)
	setLanternCollision(lantern, true)

	if lantern:IsA("Model") then
		local origCF = originalData[lantern].CFrame
		local origScale = originalData[lantern].Scale

		-- 本来の位置より 6studs 下の高さからスタート
		local startCF = origCF * CFrame.new(0, -6, 0)
		lantern:PivotTo(startCF)
		lantern:ScaleTo(origScale)

		local startTime = os.clock()

		activeAnimConnection = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - startTime
			local alpha = math.clamp(elapsed / ANIM_TIME, 0, 1)

			-- 滑らかに減速するイージング (Quad Out)
			local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			local currentCF = startCF:Lerp(origCF, easedAlpha)
			lantern:PivotTo(currentCF)

			if alpha >= 1 then
				if activeAnimConnection then
					activeAnimConnection:Disconnect()
					activeAnimConnection = nil
				end
				lantern:PivotTo(origCF)
			end
		end)
	end
end

-- ------------------------------------------------------------
-- 判定エリアの定義（検知範囲を狭く調整）
-- ------------------------------------------------------------
local zoneCenter = Vector3.new(-76, 7, 39)
-- 元のサイズ（35, 15, 45）から、X方向とZ方向の範囲を狭く調整
local zoneSize = Vector3.new(20, 15, 25)

local function isPlayerInZone(position)
	local minX = zoneCenter.X - zoneSize.X / 2
	local maxX = zoneCenter.X + zoneSize.X / 2
	local minY = zoneCenter.Y - zoneSize.Y / 2
	local maxY = zoneCenter.Y + zoneSize.Y / 2
	local minZ = zoneCenter.Z - zoneSize.Z / 2
	local maxZ = zoneCenter.Z + zoneSize.Z / 2

	return position.X >= minX and position.X <= maxX
		and position.Y >= minY and position.Y <= maxY
		and position.Z >= minZ and position.Z <= maxZ
end

-- 状態管理フラグ
local isInsideZone = false
local isAnimating = false

-- ------------------------------------------------------------
-- メインの演出処理シーケンス
-- ------------------------------------------------------------
local function triggerSequence()
	if isAnimating or not isInsideZone then return end
	isAnimating = true

	-- 湧き上がりアニメーション実行
	playRiseAnimation()

	-- アニメーション完了（1.2秒）まで待機
	task.wait(ANIM_TIME)

	-- エリア内に留まっている場合のみ、一拍おいて SE_DEDEN を再生
	if isInsideZone then
		task.wait(0.5) -- 一拍の間隔
		if soundDeden and isInsideZone then
			soundDeden.TimePosition = 0
			soundDeden:Play()
		end
	end

	isAnimating = false
end

-- ------------------------------------------------------------
-- プレイヤーの位置監視ループ
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrpPos = char.HumanoidRootPart.Position
		local currentlyInside = isPlayerInZone(hrpPos)

		if currentlyInside and not isInsideZone then
			isInsideZone = true
			task.spawn(triggerSequence)
		elseif not currentlyInside and isInsideZone then
			isInsideZone = false
			isAnimating = false
			if activeAnimConnection then
				activeAnimConnection:Disconnect()
				activeAnimConnection = nil
			end
			hideLantern() -- エリア外に出たら非表示にリセット
		end
	end
end)
