-- ============================================================
-- 隅田川：カモメの飛行・出現演出スクリプト（エラー修正・水平飛行版）
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

local seagullSound = audioFolder and audioFolder:WaitForChild("SE_Seagull", 10)
if seagullSound then
	seagullSound.Volume = 0.5
	seagullSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > SumidaRiver フォルダからカモメプロップを取得 (01〜03)
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local sumidaFolder = propsFolder and propsFolder:WaitForChild("SumidaRiver", 10)

if not sumidaFolder then
	warn("Props/SumidaRiver フォルダが見つかりません")
	return
end

local gulls = {}
for i = 1, 3 do
	local gullName = string.format("Prop_Seagul_%02d", i)
	local gull = sumidaFolder:WaitForChild(gullName, 5)
	if gull then
		table.insert(gulls, gull)
	else
		warn(gullName .. " が見つかりませんでした")
	end
end

-- ------------------------------------------------------------
-- ★ 各カモメの本来の位置（CFrame / スケール）を記録
-- ------------------------------------------------------------
local originalData = {}
for _, gull in ipairs(gulls) do
	if gull:IsA("Model") then
		originalData[gull] = {
			Scale = gull:GetScale(),
			CFrame = gull:GetPivot()
		}
	elseif gull:IsA("BasePart") then
		originalData[gull] = {
			Size = gull.Size,
			CFrame = gull.CFrame
		}
	end
end

-- ------------------------------------------------------------
-- 透明度・コリジョン設定用ヘルパー関数
-- ------------------------------------------------------------
local function setGullTransparency(target, transparency)
	if target:IsA("BasePart") then
		target.Transparency = transparency
		target.CanCollide = (transparency == 0)
	elseif target:IsA("Model") then
		for _, child in ipairs(target:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = transparency
				child.CanCollide = (transparency == 0)
			end
		end
	end
end

-- 初期化（開始時は非表示）
local function hideAllGulls()
	for _, gull in ipairs(gulls) do
		setGullTransparency(gull, 1)
		if originalData[gull] then
			if gull:IsA("Model") then
				gull:PivotTo(originalData[gull].CFrame)
			elseif gull:IsA("BasePart") then
				gull.CFrame = originalData[gull].CFrame
			end
		end
	end
end

hideAllGulls()

-- ------------------------------------------------------------
-- 検知エリアの範囲定義（4つの座標をもとにした矩形判定）
-- X: -103 ～ -69 / Z: 9 ～ 39
-- ------------------------------------------------------------
local minX, maxX = -103, -69
local minZ, maxZ = 9, 39

local function isPlayerInZone(position)
	return position.X >= minX and position.X <= maxX 
		and position.Z >= minZ and position.Z <= maxZ
end

-- 状態管理フラグ
local isInside = false
local isAnimating = false
local activeConnection = nil

-- ------------------------------------------------------------
-- 高さ（Y軸）を変えずに水平飛行しながら出現する演出
-- ------------------------------------------------------------
local function playFlightAnimation()
	if isAnimating then return end
	isAnimating = true

	-- 進行中のアニメーションがあれば一旦切断
	if activeConnection then
		activeConnection:Disconnect()
		activeConnection = nil
	end

	-- 1. カモメの鳴き声（SE_Seagull）を再生
	if seagullSound then
		seagullSound.TimePosition = 0
		seagullSound:Play()
	end

	-- 2. 各カモメを表示状態にして、少し離れたスタート位置に配置
	local flightDuration = 2.0 -- 飛行にかかる時間（秒）

	for _, gull in ipairs(gulls) do
		if originalData[gull] then
			local origCF = originalData[gull].CFrame
			-- 高さ（Y軸）を変えず（0）、XとZ方向のみオフセットした位置からスタート
			local startCF = origCF + Vector3.new(-15, 0, -10)

			if gull:IsA("Model") then
				gull:PivotTo(startCF)
			elseif gull:IsA("BasePart") then
				gull.CFrame = startCF
			end
			setGullTransparency(gull, 0)
		end
	end

	-- 3. Heartbeatで本来の位置（origCF）へ水平にスライド移動させる
	local startTime = os.clock()
	activeConnection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / flightDuration, 0, 1)

		-- 滑らかなイージング
		local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for _, gull in ipairs(gulls) do
			if originalData[gull] then
				local origCF = originalData[gull].CFrame
				local startCF = origCF + Vector3.new(-15, 0, -10)
				local currentCF = startCF:Lerp(origCF, easedAlpha)

				if gull:IsA("Model") then
					gull:PivotTo(currentCF)
				elseif gull:IsA("BasePart") then
					gull.CFrame = currentCF
				end
			end
		end

		if alpha >= 1 then
			if activeConnection then
				activeConnection:Disconnect()
				activeConnection = nil
			end
			isAnimating = false
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
			playFlightAnimation()

		elseif not currentlyInside and isInside then
			-- エリアから外れた瞬間
			isInside = false
			isAnimating = false

			if activeConnection then
				activeConnection:Disconnect()
				activeConnection = nil
			end

			-- 範囲外に出たら非表示にリセット
			hideAllGulls()
		end
	end
end)
