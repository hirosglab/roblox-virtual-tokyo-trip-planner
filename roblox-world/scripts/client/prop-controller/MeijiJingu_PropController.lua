-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local propsFolder = Workspace:WaitForChild("Props"):WaitForChild("MeijiJingu")
local audioAssets = Workspace:WaitForChild("AudioAssets")
local sound = audioAssets:WaitForChild("SE_Relaxing_Birds")

-- 出現の順番（8個ずつのグループ：奥から手前へ）
local leafGroups = {
	{33, 40},
	{25, 32},
	{17, 24},
	{9, 16},
	{1, 8}
}

-- 葉っぱのオブジェクトを事前に取得し、最初は非表示にしておく
local leaves = {}
for i = 1, 40 do
	local name = string.format("Prop_Ginkgo-Leaf_%02d", i)
	local leaf = propsFolder:FindFirstChild(name)
	if leaf then
		leaves[i] = leaf
		for _, descendant in ipairs(leaf:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
				descendant.CanCollide = false
			end
		end
		if leaf:IsA("BasePart") then
			leaf.Transparency = 1
			leaf.CanCollide = false
		end
	end
end

-- 判定エリア
local zoneCenter = Vector3.new(0.5, 6, -95)
local zoneSize = Vector3.new(25, 20, 30)

local isInsideZone = false
local isAnimating = false
local hasPlayedSound = false

-- プレイヤーがエリア内にいるかを判定する関数
local function isPlayerInZone(position)
	local minX = zoneCenter.X - zoneSize.X / 2
	local maxX = zoneCenter.X + zoneSize.X / 2
	local minY = zoneCenter.Y - zoneSize.Y / 2
	local maxY = zoneCenter.Y + zoneSize.Y / 2
	local minZ = zoneCenter.Z - zoneSize.Z / 2
	local maxZ = zoneCenter.Z + zoneSize.Z / 2

	return position.X >= minX and position.X <= maxX and
		position.Y >= minY and position.Y <= maxY and
		position.Z >= minZ and position.Z <= maxZ
end

-- すべての葉を非表示にする関数
local function hideAllLeaves()
	for _, leaf in pairs(leaves) do
		for _, descendant in ipairs(leaf:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
				descendant.CanCollide = false
			end
		end
		if leaf:IsA("BasePart") then
			leaf.Transparency = 1
			leaf.CanCollide = false
		end
	end
	hasPlayedSound = false
end

-- 順番に葉を表示する関数
local function showLeavesSequence()
	if isAnimating or not isInsideZone then return end
	isAnimating = true

	for _, group in ipairs(leafGroups) do
		-- 途中でエリア外に出たらアニメーションを中断
		if not isInsideZone then
			isAnimating = false
			return
		end

		for i = group[1], group[2] do
			local leaf = leaves[i]
			if leaf then
				for _, descendant in ipairs(leaf:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Transparency = 0
					end
				end
				if leaf:IsA("BasePart") then
					leaf.Transparency = 0
				end
			end
		end
		task.wait(0.4)
	end

	isAnimating = false

	-- すべての表示が終わった後にサウンドを再生（エリア内に留まっている場合のみ）
	if isInsideZone and not hasPlayedSound and sound and sound:IsA("Sound") then
		sound:Play()
		hasPlayedSound = true
	end
end

-- 毎フレームプレイヤーの位置を監視して出入りを判定
RunService.Heartbeat:Connect(function()
	local character = localPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		local currentlyInside = isPlayerInZone(rootPart.Position)

		if currentlyInside and not isInsideZone then
			-- エリアに入った瞬間
			isInsideZone = true
			task.spawn(showLeavesSequence)
		elseif not currentlyInside and isInsideZone then
			-- エリアから離れた瞬間
			isInsideZone = false
			isAnimating = false
			hideAllLeaves()
		end
	end
end)
