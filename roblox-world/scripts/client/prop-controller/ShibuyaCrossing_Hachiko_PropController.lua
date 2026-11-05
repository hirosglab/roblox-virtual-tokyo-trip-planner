-- ============================================================
-- 渋谷交差点：柴犬プロップ時間差出現スクリプト（アニメーション対応版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ（交差点タイルと効果音が重ならないよう距離を狭めに設定）
local TRIGGER_DISTANCE = 8.5 -- 反応する距離（studs）
local DELAY_TIME = 0.25      -- 各プロップ間の待ち時間（秒）
local TWEEN_TIME = 0.35      -- ポップアップにかかる時間（秒）

-- ------------------------------------------------------------
-- 1. サウンド（SE_Pop_Common, SE_Puppy）の参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
if not audioFolder then
	local propsFolder = workspace:FindFirstChild("Props")
	if propsFolder then
		audioFolder = propsFolder:FindFirstChild("AudioAssets")
	end
end

local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)
local puppySound = audioFolder and audioFolder:WaitForChild("SE_Puppy", 10)

if popSound then
	popSound.Volume = 0.8
	popSound.RollOffMaxDistance = 50
end

if puppySound then
	puppySound.Volume = 0.8
	puppySound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > ShibuyaCrossing フォルダから柴犬プロップを取得 (01〜03)
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local shibuyaFolder = propsFolder and propsFolder:WaitForChild("ShibuyaCrossing", 10)

if not shibuyaFolder then
	warn("Props/ShibuyaCrossing フォルダが見つかりません")
	return
end

local allProps = {}
for i = 1, 3 do
	local propName = string.format("Prop_Shibainu_%02d", i)
	local prop = shibuyaFolder:WaitForChild(propName, 5)
	if prop then
		table.insert(allProps, prop)
	else
		warn(propName .. " が見つかりませんでした")
	end
end

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
-- 全パーツのCanCollide（衝突判定）を自動でオフにする補助処理
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
local function hideAllShibainu()
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
hideAllShibainu()

-- ------------------------------------------------------------
-- 効果音再生用ヘルパー関数
-- ------------------------------------------------------------
local function playPopSound()
	if popSound then
		popSound.TimePosition = 0
		popSound:Play()
	end
end

local function playPuppySound()
	if puppySound then
		puppySound.TimePosition = 0
		puppySound:Play()
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
-- 順次出現アニメーション
-- ------------------------------------------------------------
local function showShibainuSequence()
	isAnimating = true

	-- 1体ずつ時間差でポップアップさせながら SE_Pop_Common を鳴らす
	for _, prop in ipairs(allProps) do
		playPopSound()
		animatePopIn(prop)
		task.wait(DELAY_TIME)
	end

	-- 3つすべて表示してから1秒待ってから SE_Puppy を再生
	task.wait(1.0)
	playPuppySound()

	isAnimating = false
end

-- ------------------------------------------------------------
-- ★ プレイヤーとの距離判定（柴犬の中点基準）
-- ------------------------------------------------------------
local shibainuCenter = Vector3.new(
	(89 + 83 + 87) / 3,
	0,
	(-46 + -56 + -52) / 3
)

local function checkPlayerInRange()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrpPos = char.HumanoidRootPart.Position
		local playerXZ = Vector3.new(hrpPos.X, 0, hrpPos.Z)
		local centerXZ = Vector3.new(shibainuCenter.X, 0, shibainuCenter.Z)
		local dist = (playerXZ - centerXZ).Magnitude
		return dist <= TRIGGER_DISTANCE
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
			task.spawn(showShibainuSequence)
		end

	elseif not isInRange and isNear then
		isNear = false
		-- 範囲外に出たら非表示（初期状態）に戻す
		hideAllShibainu()
	end
end)
