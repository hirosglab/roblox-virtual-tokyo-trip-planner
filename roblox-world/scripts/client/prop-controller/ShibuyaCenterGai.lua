-- ============================================================
-- センター街：ショッピングバッグ回転スクリプト（複数バッグ対応版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ
local TRIGGER_DISTANCE = 40  -- 反応する距離（studs）
local ROTATION_SPEED = 45    -- 1秒あたりの回転角度（度）

-- 1. 対象の InfoBoard の取得

local boardsFolder = workspace:WaitForChild("Featured_Sightseeing_Spots_Boards", 10)
local board = boardsFolder and boardsFolder:WaitForChild("InfoBoard_09_ShibuyaCenterGai", 10)

if not board then
	warn("InfoBoard_09_ShibuyaCenterGai が Featured_Sightseeing_Spots_Boards 内で見つかりません")
	return
end

-- 2. Props > ShibuyaCenterGai フォルダからバッグを取得

local propsFolder = workspace:WaitForChild("Props", 10)
local shibuyaCenterGaiFolder = propsFolder and propsFolder:WaitForChild("ShibuyaCenterGai", 10)

if not shibuyaCenterGaiFolder then
	warn("Props/ShibuyaCenterGai フォルダが見つかりません")
	return
end

local shoppingBag1 = shibuyaCenterGaiFolder:WaitForChild("Prop_Shopping_Bag_05", 10)
local shoppingBag2 = shibuyaCenterGaiFolder:WaitForChild("Prop_Shopping_Bag_06", 10)

local shoppingBags = {}
if shoppingBag1 then table.insert(shoppingBags, shoppingBag1) else warn("Prop_Shopping_Bag_05 が見つかりません") end
if shoppingBag2 then table.insert(shoppingBags, shoppingBag2) else warn("Prop_Shopping_Bag_06 が見つかりません") end

-- ★ 初期位置・CFrameの記録

local originalData = {}

for _, bag in ipairs(shoppingBags) do
	if bag:IsA("Model") then
		originalData[bag] = bag:GetPivot()
	elseif bag:IsA("BasePart") then
		originalData[bag] = bag.CFrame
	end
end

-- 状態管理フラグ
local isNear = false

-- ============================================================
-- ★ 自分自身（LocalPlayer）との距離と「前方」の判定関数
-- ============================================================
local function checkPlayerInFront()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		local boardPivot = board:GetPivot()
		local boardPos = boardPivot.Position

		-- 1. まず距離のチェック（40 studs以内か）
		local dist = (hrp.Position - boardPos).Magnitude
		if dist > TRIGGER_DISTANCE then
			return false
		end

		-- 近づきすぎたとき（例：15 studs以内）は、角度に関わらず正面にいるとみなす
		if dist <= 15 then
			return true
		end

		-- 2. 看板の正面方向ベクトル
		local boardForward = -boardPivot.LookVector

		-- 3. 看板からプレイヤーへのベクトル
		local toPlayer = (hrp.Position - boardPos)

		-- 高低差（Y軸）の影響を無視して、水平方向（XZ平面）だけで判定
		toPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
		boardForward = Vector3.new(boardForward.X, 0, boardForward.Z)

		if toPlayer.Magnitude == 0 or boardForward.Magnitude == 0 then
			return false
		end

		toPlayer = toPlayer.Unit
		boardForward = boardForward.Unit

		-- 4. 内積を計算（0.9 = 約25度以内の視野角）
		local dot = boardForward:Dot(toPlayer)
		return dot > 0.9
	end
	return false


end

-- 判定・回転ループ（Heartbeat）

RunService.Heartbeat:Connect(function(dt)
	local isInFront = checkPlayerInFront()

	if isInFront then
		if not isNear then
			isNear = true
		end

		-- 接近中は全バッグをY軸周りに継続して回転させる
		local rotationDelta = CFrame.Angles(0, math.rad(ROTATION_SPEED * dt), 0)

		for _, bag in ipairs(shoppingBags) do
			if bag then
				if bag:IsA("Model") then
					bag:PivotTo(bag:GetPivot() * rotationDelta)
				elseif bag:IsA("BasePart") then
					bag.CFrame = bag.CFrame * rotationDelta
				end
			end
		end
	else
		if isNear then
			isNear = false
			-- 範囲外に出たらすべてのバッグを元の向きにリセット
			for _, bag in ipairs(shoppingBags) do
				if bag and originalData[bag] then
					if bag:IsA("Model") then
						bag:PivotTo(originalData[bag])
					elseif bag:IsA("BasePart") then
						bag.CFrame = originalData[bag]
					end
				end
			end
		end
	end


end)

