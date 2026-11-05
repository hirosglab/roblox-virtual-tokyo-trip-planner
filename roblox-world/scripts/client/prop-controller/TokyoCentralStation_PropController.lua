-- ============================================================
-- 東京中央駅：提灯時間差出現スクリプト（青色ランタン・28個対応版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ（ゆっくり出現するように数値を調整）
local TRIGGER_DISTANCE = 22  -- 提灯の並びの中心から反応する距離（studs）
local DELAY_TIME = 0.4       -- 各グループ間の待ち時間（秒）を少し長く
local TWEEN_TIME = 0.6       -- ポップアップにかかる時間（秒）を長くしてゆっくりに

-- ------------------------------------------------------------
-- 1. サウンド（Sound）の参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local audioFolder = propsFolder and propsFolder:WaitForChild("AudioAssets", 10)
if not audioFolder then
	audioFolder = workspace:WaitForChild("AudioAssets", 10) -- フォールバック
end

local tedenSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)
local hoisasaSound = audioFolder and audioFolder:WaitForChild("SE_DEDEN", 10)

if tedenSound then
	tedenSound.Volume = 0.8
	tedenSound.RollOffMaxDistance = 50
end

if hoisasaSound then
	hoisasaSound.Volume = 0.8
	hoisasaSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > TokyoCentralStation フォルダから各ランタンを取得 (01〜28)
-- ------------------------------------------------------------
local tokyoFolder = propsFolder and propsFolder:WaitForChild("TokyoCentralStation", 10)

if not tokyoFolder then
	warn("Props/TokyoCentralStation フォルダが見つかりません")
	return
end

-- 4つのグループに分けてランタンを取得
local groups = {}
groups[1] = {}
for i = 1, 7 do table.insert(groups[1], tokyoFolder:WaitForChild(string.format("Prop_Lantern_Blue_%02d", i), 5)) end

groups[2] = {}
for i = 8, 14 do table.insert(groups[2], tokyoFolder:WaitForChild(string.format("Prop_Lantern_Blue_%02d", i), 5)) end

groups[3] = {}
for i = 15, 21 do table.insert(groups[3], tokyoFolder:WaitForChild(string.format("Prop_Lantern_Blue_%02d", i), 5)) end

groups[4] = {}
for i = 22, 28 do table.insert(groups[4], tokyoFolder:WaitForChild(string.format("Prop_Lantern_Blue_%02d", i), 5)) end

-- 全ランタンのリストを結合
local allProps = {}
for _, group in ipairs(groups) do
	for _, p in ipairs(group) do
		table.insert(allProps, p)
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
-- ★ Light（PointLight等）のオン/オフ切り替え補助関数
-- ------------------------------------------------------------
local function setPropLightEnabled(prop, enabled)
	if not prop then return end

	for _, child in ipairs(prop:GetDescendants()) do
		if child:IsA("Light") then
			child.Enabled = enabled
		end
	end
end

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
-- 非表示リセット処理（透明度を1にし、ライトをOFFにする）
-- ------------------------------------------------------------
local function hideAllLanterns()
	for _, prop in ipairs(allProps) do
		if prop and originalData[prop] then
			setPropTransparency(prop, 1)
			setPropLightEnabled(prop, false)

			if prop:IsA("Model") then
				prop:ScaleTo(originalData[prop].Scale)
			elseif prop:IsA("BasePart") then
				prop.Size = originalData[prop].Size
			end
		end
	end
end

-- 初期化（開始時は非表示・消灯）
hideAllLanterns()

-- ------------------------------------------------------------
-- 効果音再生用ヘルパー関数
-- ------------------------------------------------------------
local function playTedenSound()
	if tedenSound then
		tedenSound.TimePosition = 0
		tedenSound:Play()
	end
end

local function playHoisasaSound()
	if hoisasaSound then
		hoisasaSound.TimePosition = 0
		hoisasaSound:Play()
	end
end

-- ------------------------------------------------------------
-- ★ ポップアップアニメーション（ライトは点灯させずオフのまま）
-- ------------------------------------------------------------
local popTweenInfo = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local function animatePopIn(prop)
	if not prop or not originalData[prop] then return end

	setPropTransparency(prop, 0)
	-- ライトは点灯させない（オフのまま維持）

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
-- 順次出現アニメーション（グループごとに順番に出現）
-- ------------------------------------------------------------
local function showLanternSequence()
	isAnimating = true

	for i, group in ipairs(groups) do
		playTedenSound()
		for _, prop in ipairs(group) do
			animatePopIn(prop)
		end

		-- 最後のグループでなければウェイトを入れる
		if i < #groups then
			task.wait(DELAY_TIME)
		end
	end

	-- すべて表示完了後に2秒ほど置いてから SE_DEDEN を再生
	task.wait(1.0)
	playHoisasaSound()

	isAnimating = false
end

-- ============================================================
-- ★ プレイヤーが提灯の近く（エリア内）にいるかの判定関数
-- ============================================================
local function checkPlayerInRange()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart

		-- Prop_Lantern_Blue_01 と Prop_Lantern_Blue_07 の中点を基準にする
		local p1 = groups[1][1]
		local p7 = groups[1][#groups[1]]

		if p1 and p7 then
			local pos1 = p1:GetPivot().Position
			local pos7 = p7:GetPivot().Position
			local centerPos = (pos1 + pos7) / 2

			local playerPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
			local targetCenter = Vector3.new(centerPos.X, 0, centerPos.Z)
			local dist = (playerPos - targetCenter).Magnitude

			return dist <= TRIGGER_DISTANCE
		end
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
			showLanternSequence()
		end

	elseif not isInRange and isNear then
		isNear = false
		hideAllLanterns()
	end
end)
