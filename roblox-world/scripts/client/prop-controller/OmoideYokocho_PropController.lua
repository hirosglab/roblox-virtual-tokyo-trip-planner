-- ============================================================
-- 思い出横丁エリア：提灯時間差出現スクリプト（X方向およびZ方向のマージン個別調整版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ
local DELAY_TIME = 0.25      -- 各ステップ間の待ち時間（秒）
local TWEEN_TIME = 0.35      -- ポップアップにかかる時間（秒）

-- ------------------------------------------------------------
-- 1. 対象の InfoBoard およびフォルダの取得
-- ------------------------------------------------------------
local boardsFolder = workspace:WaitForChild("Featured_Sightseeing_Spots_Boards", 10)
local board = boardsFolder and boardsFolder:WaitForChild("InfoBoard_02_OmoideYokocho", 10)

if not board then
	warn("InfoBoard_02_OmoideYokocho が Featured_Sightseeing_Spots_Boards 内で見つかりません")
	return
end

-- サウンド（Sound）の参照
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)
local welcomeSound = audioFolder and audioFolder:WaitForChild("SE_Welcome_Izakaya", 10)

if popSound then
	popSound.SoundId = "rbxassetid://100517105966579"
	popSound.Volume = 0.8
	popSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > OmoideYokocho フォルダから各提灯を取得
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props"):WaitForChild("OmoideYokocho", 10)

if not propsFolder then
	warn("Props/OmoideYokocho フォルダが見つかりません")
	return
end

local p_Lantern1 = propsFolder:WaitForChild("Prop_Lantern_Red_01")
local p_Lantern2 = propsFolder:WaitForChild("Prop_Lantern_Red_02")
local p_Lantern3 = propsFolder:WaitForChild("Prop_Lantern_Red_03")
local p_Lantern4 = propsFolder:WaitForChild("Prop_Lantern_Red_04")
local p_Lantern5 = propsFolder:WaitForChild("Prop_Lantern_Red_05")
local p_Lantern6 = propsFolder:WaitForChild("Prop_Lantern_Red_06")
local p_Lantern7 = propsFolder:WaitForChild("Prop_Lantern_Red_07")
local p_Lantern8 = propsFolder:WaitForChild("Prop_Lantern_Red_08")

local allProps = {
	p_Lantern1, p_Lantern2,
	p_Lantern3, p_Lantern4,
	p_Lantern5, p_Lantern6,
	p_Lantern7, p_Lantern8
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
local function playPopSound()
	if popSound then
		popSound.TimePosition = 0
		popSound:Play()
	end
end

local function playWelcomeSound()
	if welcomeSound then
		welcomeSound.TimePosition = 0
		welcomeSound:Play()
	end
end

-- ------------------------------------------------------------
-- ★ ポップアップアニメーション（出現時にライトON）
-- ------------------------------------------------------------
local popTweenInfo = TweenInfo.new(
	TWEEN_TIME,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local function animatePopIn(prop)
	if not prop or not originalData[prop] then return end

	setPropTransparency(prop, 0)
	setPropLightEnabled(prop, true)

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
-- 順次出現アニメーション（ペアで2個ずつ出現）
-- ------------------------------------------------------------
local function showLanternSequence()
	isAnimating = true

	playPopSound()
	animatePopIn(p_Lantern1)
	animatePopIn(p_Lantern2)
	task.wait(DELAY_TIME)

	playPopSound()
	animatePopIn(p_Lantern3)
	animatePopIn(p_Lantern4)
	task.wait(DELAY_TIME)

	playPopSound()
	animatePopIn(p_Lantern5)
	animatePopIn(p_Lantern6)
	task.wait(DELAY_TIME)

	playPopSound()
	animatePopIn(p_Lantern7)
	animatePopIn(p_Lantern8)

	playWelcomeSound()

	isAnimating = false
end

-- ============================================================
-- ★ X方向・Z方向のマージンを個別に調整した範囲判定関数
-- ============================================================
local function checkPlayerInArea()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		local pPos = hrp.Position

		-- 対象の基準ポイントリスト（思い出横丁関連）
		local targetPoints = {
			Vector3.new(-90.93, 7, -52.5), -- InfoBoard_02_OmoideYokocho
			Vector3.new(-94, 12, -41),       -- Prop_Lantern_Red_07
			Vector3.new(-87, 12, -52),       -- Prop_Lantern_Red_08
			Vector3.new(-74, 12, -30),       -- Prop_Lantern_Red_01
			Vector3.new(-68, 12, -43)        -- Prop_Lantern_Red_02
		}

		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge

		for _, pt in ipairs(targetPoints) do
			if pt.X < minX then minX = pt.X end
			if pt.X > maxX then maxX = pt.X end
			if pt.Z < minZ then minZ = pt.Z end
			if pt.Z > maxZ then maxZ = pt.Z end
		end

		-- 【調整用マージン】
		-- X方向（新宿東口側：(-79.93) や 歌舞伎町側：(-101.93) への広がり）のマージンを狭めて、隣の看板前での誤反応を防ぎます
		local MARGIN_X = 3   -- X方向のマージンを小さくする（例: 10 から 3 へ縮小）
		local MARGIN_Z = 3   -- Z方向の奥行きマージン

		minX = minX - MARGIN_X
		maxX = maxX + MARGIN_X
		minZ = minZ - MARGIN_Z
		maxZ = maxZ + MARGIN_Z

		if pPos.X >= minX and pPos.X <= maxX and pPos.Z >= minZ and pPos.Z <= maxZ then
			return true
		end
	end
	return false
end

-- ------------------------------------------------------------
-- 判定ループ（Heartbeat）
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local isInArea = checkPlayerInArea()

	if isInArea and not isNear then
		isNear = true
		if not isAnimating then
			showLanternSequence()
		end

	elseif not isInArea and isNear then
		isNear = false
		hideAllLanterns()
	end
end)
