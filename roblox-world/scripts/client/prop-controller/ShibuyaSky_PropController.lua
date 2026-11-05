-- ============================================================
-- Prop_Shibuya_Sky Controller（安定化・最適化版）
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local localPlayer = Players.LocalPlayer

task.spawn(function()
	local props = workspace:WaitForChild("Props", 10)
	if not props then return end
	local shibuyaSky = props:WaitForChild("ShibuyaSky", 10)
	if not shibuyaSky then return end
	local prop = shibuyaSky:WaitForChild("Prop_Shibuya_Sky", 10)
	if not prop then return end

	local surfaceGui = prop:WaitForChild("SurfaceGui", 10)
	if not surfaceGui then return end
	local imageLabel = surfaceGui:WaitForChild("ImageLabel_ShibuyaSky", 10)
	if not imageLabel then return end

	-- 初期状態を非表示に設定
	imageLabel.Visible = false

	-- 画像の事前読み込み
	if imageLabel.Image ~= "" then
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({imageLabel})
			end)
		end)
	end

	local lastVisibleState = false

	-- 毎フレームプレイヤーの位置をチェック
	RunService.RenderStepped:Connect(function()
		local character = localPlayer.Character
		if not character then
			if lastVisibleState then
				lastVisibleState = false
				imageLabel.Visible = false
			end
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			if lastVisibleState then
				lastVisibleState = false
				imageLabel.Visible = false
			end
			return
		end

		-- プレイヤーの位置をローカル座標に変換
		local localPos = prop.CFrame:PointToObjectSpace(rootPart.Position)

		local size = prop.Size
		local margin = 2 -- 判定の余裕を少し広げる（ちらつき防止）

		local isInsideX = math.abs(localPos.X) <= (size.X / 2 + margin)
		local isInsideZ = math.abs(localPos.Z) <= (size.Z / 2 + margin)
		local isAboveY = localPos.Y >= (size.Y / 2 - 0.5) and localPos.Y <= (size.Y / 2 + 6)

		local shouldBeVisible = (isInsideX and isInsideZ and isAboveY)

		-- ★ 状態が変化したときだけ Visible を書き換える（負荷とちらつきを軽減）
		if shouldBeVisible ~= lastVisibleState then
			lastVisibleState = shouldBeVisible
			imageLabel.Visible = shouldBeVisible
		end
	end)
end)
