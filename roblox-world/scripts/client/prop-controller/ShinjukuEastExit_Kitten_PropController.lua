-- ============================================================
-- 新宿東口：子猫プロップ出現・音声再生スクリプト（修正版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ
local TRIGGER_DISTANCE = 20 -- 反応する距離（studs）
local TWEEN_TIME = 0.35      -- ポップアップにかかる時間（秒）

-- ------------------------------------------------------------
-- 1. サウンドの参照
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
if not audioFolder then
	local propsFolder = workspace:FindFirstChild("Props")
	if propsFolder then
		audioFolder = propsFolder:FindFirstChild("AudioAssets")
	end
end

local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)
local kittenSound = audioFolder and audioFolder:WaitForChild("SE_Kitten", 10)

if popSound then
	popSound.Volume = 0.8
	popSound.RollOffMaxDistance = 50
end

if kittenSound then
	kittenSound.Volume = 0.8
	kittenSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Prop_Kitten の取得
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local shinjukuFolder = propsFolder and propsFolder:WaitForChild("ShinjukuEastExit", 10)

if not shinjukuFolder then
	warn("Props/ShinjukuEastExit フォルダが見つかりません")
	return
end

local kittenProp = shinjukuFolder:WaitForChild("Prop_Kitten", 5)
if not kittenProp then
	warn("Prop_Kitten が見つかりませんでした")
	return
end

-- ------------------------------------------------------------
-- プロップの初期サイズ・位置・スケールの記録
-- ------------------------------------------------------------
local originalData = {}

if kittenProp:IsA("Model") then
	originalData[kittenProp] = {
		Scale = kittenProp:GetScale(),
		CFrame = kittenProp:GetPivot()
	}
elseif kittenProp:IsA("BasePart") then
	originalData[kittenProp] = {
		Size = kittenProp.Size,
		CFrame = kittenProp.CFrame
	}
end

-- 状態管理フラグ（最初を nil にして、初回判定で必ず状態が切り替わるようにする）
local isNear = nil
local isAnimating = false

-- ------------------------------------------------------------
-- 透明度切り替え補助関数
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 衝突判定オフ補助処理
-- ------------------------------------------------------------
local function disableCollision(prop)
	if not prop then return end

	if prop:IsA("BasePart") then
		prop.CanCollide = false
	elseif prop:IsA("Model") then
		for _, child in ipairs(prop:GetDescendants()) do
			if child:IsA("BasePart") then
				child.CanCollide = false
			end
		end
	end
end

-- ------------------------------------------------------------
-- 非表示リセット処理
-- ------------------------------------------------------------
local function hideKitten()
	if kittenProp and originalData[kittenProp] then
		setPropTransparency(kittenProp, 1)
		disableCollision(kittenProp)
		if kittenProp:IsA("Model") then
			kittenProp:ScaleTo(originalData[kittenProp].Scale)
		elseif kittenProp:IsA("BasePart") then
			kittenProp.Size = originalData[kittenProp].Size
		end
	end
end

-- ------------------------------------------------------------
-- 効果音再生用ヘルパー関数
-- ------------------------------------------------------------
local function playPopSound()
	if popSound then
		popSound.TimePosition = 0
		popSound:Play()
	end
end

local function playKittenSound()
	if kittenSound then
		kittenSound.TimePosition = 0
		kittenSound:Play()
	end
end

-- ------------------------------------------------------------
-- ポップアップアニメーション
-- ------------------------------------------------------------
local popTweenInfo = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local function animatePopIn(prop)
	if not prop or not originalData[prop] then return end

	setPropTransparency(prop, 0)
	disableCollision(prop)

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

	elseif prop:IsA("BasePart") then
		local origCF = originalData[prop].CFrame
		local origSize = originalData[prop].Size

		prop.CFrame = origCF * CFrame.new(0, -5, 0)
		prop.Size = origSize * 0.2

		local tweenSize = TweenService:Create(prop, popTweenInfo, {
			Size = origSize,
			CFrame = origCF
		})
		tweenSize:Play()
	end
end

local function showKittenSequence()
	isAnimating = true

	playPopSound()
	animatePopIn(kittenProp)

	task.wait(1.0)
	playKittenSound()

	isAnimating = false
end

-- ------------------------------------------------------------
-- 距離判定関数
-- ------------------------------------------------------------
local function getKittenPosition()
	if kittenProp:IsA("Model") then
		return kittenProp:GetPivot().Position
	elseif kittenProp:IsA("BasePart") then
		return kittenProp.Position
	end
	return Vector3.new(-79, 12, -69)
end

local function checkPlayerInRange()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrpPos = char.HumanoidRootPart.Position
		local kittenPos = getKittenPosition()

		local playerXZ = Vector3.new(hrpPos.X, 0, hrpPos.Z)
		local kittenXZ = Vector3.new(kittenPos.X, 0, kittenPos.Z)
		local dist = (playerXZ - kittenXZ).Magnitude
		return dist <= TRIGGER_DISTANCE
	end
	return false
end

-- ------------------------------------------------------------
-- 判定ループ（Heartbeat）
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local isInRange = checkPlayerInRange()

	-- 初回、または状態が切り替わったときのみ処理を実行
	if isInRange ~= isNear then
		isNear = isInRange

		if isNear then
			if not isAnimating then
				task.spawn(showKittenSequence)
			end
		else
			hideKitten()
		end
	end
end)
