--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--// Constants
const ToggleIKControl = function(NilNetworkAlign : typeof(ReplicatedStorage.Aligns), Bool : boolean)
	NilNetworkAlign.Enabled = Bool
end
const IsServerOwned = setmetatable({}, {__mode = "k"})
const CameraCFrames = setmetatable({}, {__mode = "k"})
const AllPlayers = Players:GetPlayers()

--// Events
ReplicatedStorage.Update.OnServerEvent:Connect(function(Player, Buffer : buffer)
	local Character = Player.Character
	if Character then
		local PrimaryPart = workspace.Hurtboxes:FindFirstChild(`{Character}__SS`)
		if PrimaryPart then
			local R02, R22 = Buffer and tonumber(buffer.readf32(Buffer, 0)), Buffer and tonumber(buffer.readf32(Buffer, 4))
			if not R02 or not R22 then
				CameraCFrames[Character] = nil
			else
				CameraCFrames[Character] = math.atan2(R02, R22)
			end
			R02, R22 = nil, nil
		end
		PrimaryPart = nil
		
		Buffer = nil
	end
end)
ReplicatedStorage.Settings.OnServerEvent:Connect(function(Player, Buffer : buffer)
	local Character = Player.Character
	if Character then
		local Humanoid : Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			local Setting = buffer.readf32(Buffer, 0)
			if Setting == 0 then
				Humanoid.WalkSpeed = tonumber(buffer.readf32(Buffer, 4)) or 16
			elseif Setting == 1 then
				Humanoid.JumpPower = tonumber(buffer.readf32(Buffer, 4)) or 50
			elseif Setting == 2 then
				local Active = not Character:GetAttribute("SAMActive") do
					Character:SetAttribute("SAMActive", Active)
				end
				Player.PlayerGui.Settings.SAMActive.Text = Active and "ON" or "OFF"
			end
		end
		
		Buffer = nil
	end
end)

Players.PlayerAdded:Connect(function(Player)
	AllPlayers[#AllPlayers+1] = Player
	
	Player.CharacterAdded:Connect(function(Character)
		local GUID = HttpService:GenerateGUID(false)
		local Hurtbox; Character.Destroying:Once(function()
			if Hurtbox then
				Hurtbox:Destroy()
			end
			Character:SetAttribute("SAMActive")
			ReplicatedStorage.IKControls:SetAttribute(GUID)
			IsServerOwned[Character] = nil
			CameraCFrames[Character] = nil
		end)
		
		if not Character:IsDescendantOf(workspace) then
			Character:GetPropertyChangedSignal("Parent"):Wait()
		end

		local Humanoid : Humanoid = Character:WaitForChild("Humanoid") do
			Humanoid.UseJumpPower = true
			task.delay(0, Humanoid.ChangeState, Humanoid, Enum.HumanoidStateType.GettingUp)
		end
		
		local Root : BasePart = Character:WaitForChild("HumanoidRootPart") do
			Character.PrimaryPart = Root
		end

		Hurtbox = Instance.fromExisting(Root) do
			Hurtbox.Anchored = true
			Hurtbox.Transparency = 0
			Hurtbox.Parent = workspace.Hurtboxes
			Hurtbox.Name = `{Character}__SS`
			Hurtbox.CanCollide = false
			Root:GetPropertyChangedSignal("CFrame"):Connect(function()
				Hurtbox.CFrame = Root.CFrame
			end)
		end
		do -- IKControl
			const NilNetworkAlign = Instance.fromExisting(ReplicatedStorage.Aligns) do
				NilNetworkAlign.Archivable = false
				NilNetworkAlign.Name = "NilNetworkAlign"
				NilNetworkAlign.Priority = 0
				NilNetworkAlign.EndEffector = Root
				NilNetworkAlign.ChainRoot = Root
			end
			const NetworkAttachmentPointer = Instance.new("ObjectValue") do
				NetworkAttachmentPointer.Name = "NetworkAttachment"
				const NetworkAttachment = Instance.new("Attachment") do
					NetworkAttachment.Position = Vector3.yAxis*0.001
					NetworkAttachment.Name = Character.Name
					NetworkAttachment.Parent = Hurtbox
					NilNetworkAlign.Target = NetworkAttachment
				end
				NetworkAttachmentPointer.Value = NetworkAttachment
				NetworkAttachmentPointer.Parent = NilNetworkAlign
			end
			NilNetworkAlign.Parent = Character
			ReplicatedStorage.IKControls:SetAttribute(GUID, NilNetworkAlign)
		end
		
		Character:SetAttribute("SAMActive", true)
	end)
	Player.CharacterRemoving:Connect(game.Destroy)
	
	Player.Destroying:Wait() do
		local Index = table.find(AllPlayers, Player)
		if Index then
			table.remove(AllPlayers, Index)
		end
	end
end)

while true do
	local DeltaTime = task.wait()
	for Index, Player in next, AllPlayers do
		local Character = Player.Character
		local Root = Character and Character.PrimaryPart
		if Root then
			local IsSAMActive = Character:GetAttribute("SAMActive")
			pcall(Root.SetNetworkOwner, Root, not IsSAMActive and Player or nil)
			
			local FoundPart : BasePart = workspace.Hurtboxes:FindFirstChild(`{Character}__SS`)
			if not FoundPart then
				continue
			end

			local NilNetworkAlign : typeof(ReplicatedStorage.Aligns)? = Character.NilNetworkAlign
			if NilNetworkAlign then
				if IsSAMActive then
					local NetworkAttachment : Attachment = NilNetworkAlign.NetworkAttachment.Value
					local Origin : CFrame do
						if NetworkAttachment then
							Origin = NetworkAttachment.WorldCFrame*Root.PivotOffset
						else
							local Pivot = Character:GetPivot()
							Origin = Pivot
							Character:PivotTo(Pivot)
						end
					end
					local WasServerOwned = IsServerOwned[Character] do
						IsServerOwned[Character] = true
					end
					if not WasServerOwned then
						task.defer(ToggleIKControl, NilNetworkAlign, true)
					else
						NilNetworkAlign.Enabled = true
					end
				elseif IsServerOwned[Character] then
					IsServerOwned[Character] = nil
					NilNetworkAlign.Enabled = false
				end
			end

			local Goal = Root.CFrame do
				local CameraCFrame = CameraCFrames[Character]
				if CameraCFrame then
					local Look = Root.CFrame.LookVector
					Goal = CFrame.Angles(0, CameraCFrame-math.atan2(-Look.X, -Look.Z), 0)*Goal.Rotation+Goal.Position
					Look = nil
				end
			end
			FoundPart.CFrame = Goal
		end
	end
end