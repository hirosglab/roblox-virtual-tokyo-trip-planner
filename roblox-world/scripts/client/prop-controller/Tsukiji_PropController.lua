-- ============================================================
-- 築地エリア：寿司プロップ時間差出現スクリプト（LocalScript ロード安全対策版）
-- 配置場所: StarterPlayer -> StarterPlayerScripts -> LocalScript
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 演出の調整パラメータ
local TRIGGER_DISTANCE = 40  -- 反応する距離（studs）
local DELAY_TIME = 0.25      -- 各ステップ間の待ち時間（秒）
local TWEEN_TIME = 0.35      -- ポップアップにかかる時間（秒）

-- ------------------------------------------------------------
-- 1. 対象の InfoBoard およびフォルダの取得（正しい親フォルダを参照）
-- ------------------------------------------------------------
local boardsFolder = workspace:WaitForChild("Featured_Sightseeing_Spots_Boards", 10)
local board = boardsFolder and boardsFolder:WaitForChild("InfoBoard_13_TsukijiOuterMarket", 10)

if not board then
	warn("InfoBoard_13_TsukijiOuterMarket が Featured_Sightseeing_Spots_Boards 内で見つかりません")
	return
end

-- サウンド（Sound）の参照
local audioFolder = workspace:WaitForChild("AudioAssets", 10)
local popSound = audioFolder and audioFolder:WaitForChild("SE_Pop_Common", 10)

if popSound then
	popSound.SoundId = "rbxassetid://100517105966579"
	popSound.Volume = 0.8
	popSound.RollOffMaxDistance = 50
end

-- 2. Props > TsukijiArea フォルダから各プロップを確実に取得（WaitForChild）
local propsFolder = workspace:WaitForChild("Props"):WaitForChild("TsukijiArea")

local p_Toro1   = propsFolder:WaitForChild("Prop_Sushi_Toro_01")
local p_Tamago1 = propsFolder:WaitForChild("Prop_Sushi_Tamago_01")
local p_Salmon1 = propsFolder:WaitForChild("Prop_Sushi_Salmon_01")

local p_Toro2   = propsFolder:WaitForChild("Prop_Sushi_Toro_02")
local p_Tamago2 = propsFolder:WaitForChild("Prop_Sushi_Tamago_02")
local p_Salmon2 = propsFolder:WaitForChild("Prop_Sushi_Salmon_02")

local p_Toro3   = propsFolder:WaitForChild("Prop_Sushi_Toro_03")
local p_Tamago3 = propsFolder:WaitForChild("Prop_Sushi_Tamago_03")
local p_Salmon3 = propsFolder:WaitForChild("Prop_Sushi_Salmon_03")

local p_Toro4   = propsFolder:WaitForChild("Prop_Sushi_Toro_04")
local p_Tamago4 = propsFolder:WaitForChild("Prop_Sushi_Tamago_04")
local p_Salmon4 = propsFolder:WaitForChild("Prop_Sushi_Salmon_04")

local allProps = {
	p_Toro1, p_Tamago1, p_Salmon1,
	p_Toro2, p_Tamago2, p_Salmon2,
	p_Toro3, p_Tamago3, p_Salmon3,
	p_Toro4, p_Tamago4, p_Salmon4
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
local function hideAllSushi()
	for _, prop in ipairs(allProps) do
		if prop and originalData[prop] then
			setPropTransparency(prop, 1)
			disableCollision(prop) -- 衝突無効化も同時に適用
			if prop:IsA("Model") then
				prop:ScaleTo(originalData[prop].Scale)
			elseif prop:IsA("BasePart") then
				prop.Size = originalData[prop].Size
			end
		end
	end
end

-- ------------------------------------------------------------
-- ★ 初期化処理（確実に全プロップのロードが完了してから実行）
-- ------------------------------------------------------------

hideAllSushi()


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
	Enum.EasingStyle.Back,   -- 弾むイージング
	Enum.EasingDirection.Out
)

local function animatePopIn(prop)
	if not prop or not originalData[prop] then return end

	-- 表示状態にして衝突をオフに設定
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
local function showSushiSequence()
	isAnimating = true

	-- 【Step 1】 Toro_03 & Tamago_03
	playPopSound()
	animatePopIn(p_Toro3)
	animatePopIn(p_Tamago3)
	task.wait(DELAY_TIME)

	-- 【Step 2】 Salmon_03
	playPopSound()
	animatePopIn(p_Salmon3)
	task.wait(DELAY_TIME)

	-- 【Step 3】 Toro_02 & Tamago_02
	playPopSound()
	animatePopIn(p_Toro2)
	animatePopIn(p_Tamago2)
	task.wait(DELAY_TIME)

	-- 【Step 4】 Salmon_02
	playPopSound()
	animatePopIn(p_Salmon2)
	task.wait(DELAY_TIME)

	-- 【Step 5】 Toro_01 & Tamago_01
	playPopSound()
	animatePopIn(p_Toro1)
	animatePopIn(p_Tamago1)
	task.wait(DELAY_TIME)

	-- 【Step 6】 Salmon_01
	playPopSound()
	animatePopIn(p_Salmon1)
	task.wait(DELAY_TIME)

	-- 【Step 7】 Toro_04 & Tamago_04 & Salmon_04
	playPopSound()
	animatePopIn(p_Toro4)
	animatePopIn(p_Tamago4)
	animatePopIn(p_Salmon4)

	isAnimating = false
end

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

		-- 【追加】近づきすぎたとき（15 studs以内）は、角度に関わらず正面にいるとみなして消えないようにする
		if dist <= 15 then
			return true
		end

		-- 2. 看板の正面方向ベクトル
		-- ※ Tsukijiエリアの看板も向きが逆であれば -boardPivot.LookVector にしてください
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

		-- 4. 内積を計算
		local dot = boardForward:Dot(toPlayer)

		-- 離れている時は厳めの視野角で隣の看板への誤反応を防ぐ
		return dot > 0.9
	end
	return false
end

-- ------------------------------------------------------------
-- 判定ループ（Heartbeat）
-- ------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local isInFront = checkPlayerInFront()

	if isInFront and not isNear then
		isNear = true
		if not isAnimating then
			showSushiSequence() -- ※築地エリア用の出現関数
		end

	elseif not isInFront and isNear then
		isNear = false
		hideAllSushi() -- ※築地エリア用の非表示関数
	end
end)
