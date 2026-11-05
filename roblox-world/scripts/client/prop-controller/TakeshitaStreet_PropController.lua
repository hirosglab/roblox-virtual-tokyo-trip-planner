-- ============================================================
-- Piglet & Crepe プロップ：1体ずつ順番にポップアップ・エリア検知スクリプト
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ
local DELAY_TIME = 0.2        -- 各プロップ間の待ち時間（秒）
local TWEEN_TIME = 0.35       -- ポップアップにかかる時間（秒）

-- ------------------------------------------------------------
-- 1. サウンド（SE_Pop_Common）の参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
-- ★ ここを "Pop_Common" から "SE_Pop_Common" に修正しました
local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)

if popSound then
	popSound.Volume = 0.8
	popSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Workspace > Props > TakeshitaStreet フォルダから各プロップを取得
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local takeshitaFolder = propsFolder and propsFolder:WaitForChild("TakeshitaStreet", 10)

if not takeshitaFolder then
	warn("Props/TakeshitaStreet フォルダが見つかりません")
	return
end

local allProps = {}
local pigletProps = {}
local crepeProps = {}

for i = 1, 6 do
	local pName = string.format("Prop_Piglet_%02d", i)
	local prop = takeshitaFolder:WaitForChild(pName, 5)
	if prop then
		pigletProps[i] = prop
		table.insert(allProps, prop)
	else
		warn(pName .. " が見つかりませんでした")
	end
end

for i = 1, 6 do
	local cName = string.format("Prop_Crepe_%02d", i)
	local prop = takeshitaFolder:WaitForChild(cName, 5)
	if prop then
		crepeProps[i] = prop
		table.insert(allProps, prop)
	else
		warn(cName .. " が見つかりませんでした")
	end
end

-- ------------------------------------------------------------
-- ★ 1体ずつ順番に出現させるキューストリーム（順番の定義）
-- ------------------------------------------------------------
local animationQueue = {
	crepeProps[6],
	crepeProps[5],
	pigletProps[6],
	pigletProps[5],
	crepeProps[4],
	pigletProps[4],
	crepeProps[3],
	pigletProps[3],
	crepeProps[2],
	pigletProps[2],
	crepeProps[1],
	pigletProps[1],
}

-- ------------------------------------------------------------
-- ★ 各プロップの初期サイズ・位置・スケールの記録
-- ------------------------------------------------------------
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

-- 状態管理フラグ
local isNear = false
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
-- 全パーツのCanCollide（衝突判定）をオフにする補助処理
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
local function hideAllProps()
	for _, prop in ipairs(allProps) do
		if prop and originalData[prop] then
			setPropTransparency(prop, 1)
			disableCollision(prop)
			if prop:IsA("Model") then
				prop:ScaleTo(originalData[prop].Scale)
			elseif prop:IsA("BasePart") then
				prop.Size = originalData[prop].Size
			end
		end
	end
end

-- 初期化処理（開始時は非表示・衝突無効）
hideAllProps()

-- ------------------------------------------------------------
-- 効果音再生用ヘルパー関数
-- ------------------------------------------------------------
local function playPopSound()
	if popSound then
		popSound.TimePosition = 0
		popSound:Play()
	end
end

-- ------------------------------------------------------------
-- ★ ポップアップアニメーション（位置＋サイズの弾み演出）
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

-- ------------------------------------------------------------
-- 1体ずつ順番に出現させるシーケンス
-- ------------------------------------------------------------
local function showSequence()
	isAnimating = true

	for _, prop in ipairs(animationQueue) do
		if prop then
			playPopSound()
			animatePopIn(prop)
			task.wait(DELAY_TIME)
		end
	end

	isAnimating = false
end

-- ------------------------------------------------------------
-- ★ プレイヤー検知エリアの定義
-- ------------------------------------------------------------
local detectionBox = {
	min = Vector3.new(-28, -math.huge, -100),
	max = Vector3.new(-17, math.huge, -70)
}

local function checkPlayerInRange()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local pos = char.HumanoidRootPart.Position
		return pos.X >= detectionBox.min.X and pos.X <= detectionBox.max.X
			and pos.Z >= detectionBox.min.Z and pos.Z <= detectionBox.max.Z
	end
	return false
end

-- ------------------------------------------------------------
-- 判定ループ（Heartbeat）
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local isInRange = checkPlayerInRange()

	if isInRange and not isNear then
		isNear = true
		if not isAnimating then
			task.spawn(showSequence)
		end

	elseif not isInRange and isNear then
		isNear = false
		hideAllProps()
	end
end)
