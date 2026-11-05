-- ============================================================
-- 渋谷交差点タイル：プレイヤー接近時表示・音声再生スクリプト
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ------------------------------------------------------------
-- 1. サウンド（SE_Crosswalk_Cuckoo）の参照 (Workspace > AudioAssets)
-- ------------------------------------------------------------
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
if not audioFolder then
	-- 万が一Props内にある場合のフォールバック
	local propsFolder = workspace:FindFirstChild("Props")
	if propsFolder then
		audioFolder = propsFolder:FindFirstChild("AudioAssets")
	end
end

local cuckooSound = audioFolder and audioFolder:WaitForChild("SE_Crosswalk_Cuckoo", 10)

if cuckooSound then
	cuckooSound.Volume = 0.8
	cuckooSound.RollOffMaxDistance = 50
end

-- ------------------------------------------------------------
-- 2. Props > ShibuyaCrossing フォルダからタイルを取得 (01〜25)
-- ------------------------------------------------------------
local propsFolder = workspace:WaitForChild("Props", 10)
local shibuyaFolder = propsFolder and propsFolder:WaitForChild("ShibuyaCrossing", 10)

if not shibuyaFolder then
	warn("Props/ShibuyaCrossing フォルダが見つかりません")
	return
end

-- タイル 01 〜 25 をテーブルに格納
local allTiles = {}
for i = 1, 25 do
	local tileName = string.format("Prop_Crossing_Tile_%02d", i)
	local tile = shibuyaFolder:WaitForChild(tileName, 5)
	if tile then
		table.insert(allTiles, tile)
	else
		warn(tileName .. " が見つかりませんでした")
	end
end

-- ------------------------------------------------------------
-- タイルの透明度切り替え補助関数
-- ------------------------------------------------------------
local function setTilesTransparency(transparency)
	for _, tile in ipairs(allTiles) do
		if tile then
			if tile:IsA("BasePart") then
				tile.Transparency = transparency
			elseif tile:IsA("Model") then
				for _, child in ipairs(tile:GetDescendants()) do
					if child:IsA("BasePart") then
						child.Transparency = transparency
					end
				end
			end
		end
	end
end

-- 初期化（開始時は非表示：Transparency = 1）
setTilesTransparency(1)

-- 状態管理フラグ
local isNear = false
local isAnimating = false

-- ------------------------------------------------------------
-- 3. プレイヤー検知エリアの定義（3つの直方体領域のペア）
-- 指定された6つの座標から、それぞれの範囲（Min〜Max）を定義しています
-- ------------------------------------------------------------
local detectionBoxes = {
	{ min = Vector3.new(66, -math.huge, -51), max = Vector3.new(77, math.huge, -32.5) },
	{ min = Vector3.new(56, -math.huge, -45), max = Vector3.new(67, math.huge, -27) },
	{ min = Vector3.new(55, -math.huge, -41), max = Vector3.new(62, math.huge, -28.5) },
}

-- プレイヤーの位置が指定されたボックス内にあるか判定する関数（X軸とZ軸を基準）
local function isPointInBox(pos, box)
	local xMin = math.min(box.min.X, box.max.X)
	local xMax = math.max(box.min.X, box.max.X)
	local zMin = math.min(box.min.Z, box.max.Z)
	local zMax = math.max(box.min.Z, box.max.Z)

	return pos.X >= xMin and pos.X <= xMax and pos.Z >= zMin and pos.Z <= zMax
end

local function checkPlayerInRange()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local pos = char.HumanoidRootPart.Position
		for _, box in ipairs(detectionBoxes) do
			if isPointInBox(pos, box) then
				return true
			end
		end
	end
	return false
end

-- ------------------------------------------------------------
-- 効果音再生用関数
-- ------------------------------------------------------------
local function playCuckooSound()
	if cuckooSound then
		cuckooSound.TimePosition = 0
		cuckooSound:Play()
	end
end

-- ------------------------------------------------------------
-- 表示 ＆ 1秒後の音声再生シーケンス
-- ------------------------------------------------------------
local function showTilesSequence()
	isAnimating = true

	-- タイルを表示（Transparency = 0）※表示時は効果音なし
	setTilesTransparency(0)

	-- 1秒待機してから SE_Crosswalk_Cuckoo を再生
	task.wait(0.5)
	playCuckooSound()

	isAnimating = false
end

-- ------------------------------------------------------------
-- 4. 判定ループ（Heartbeat）
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local isInRange = checkPlayerInRange()

	if isInRange and not isNear then
		isNear = true
		if not isAnimating then
			task.spawn(showTilesSequence)
		end

	elseif not isInRange and isNear then
		isNear = false
		-- 範囲外に出たらタイルを非表示（Transparency = 1）に戻す
		setTilesTransparency(1)
	end
end)
