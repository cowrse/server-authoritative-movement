--// Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const UserInputs = game:GetService("UserInputService")

--// Constants
const Player = game:GetService("Players").LocalPlayer
const Camera = workspace.CurrentCamera
const IKControlsFolder = ReplicatedStorage:WaitForChild("IKControls")
const Update = ReplicatedStorage:WaitForChild("Update")

--// Main
local IKControls : {IKControl} = IKControlsFolder:GetAttributes() do
	IKControlsFolder.AttributeChanged:Connect(function(GUID)
		local IKControlHandle : InstanceHandle = IKControlsFolder:GetAttribute(GUID)
		if IKControlHandle then
			local IKControl : IKControl = IKControlHandle:Get() or IKControlHandle:Wait() and IKControlHandle:Get()
			if not IKControl or typeof(IKControl) ~= "Instance" or not IKControl:IsA("IKControl") then
				return warn("Failed to fetch IKControl's Instance Handle. |", IKControl)
			end
			
			IKControls[GUID] = IKControl
			IKControl.Destroying:Wait() do
				local CurrentIKControl = IKControls[GUID]
				if CurrentIKControl and CurrentIKControl == GUID then
					IKControls[GUID] = nil
				end
			end
		end
	end)
end

local Character, Humanoid do
	local Update = function()
		Character = Player.Character
		if Character then
			Humanoid = Character:WaitForChild("Humanoid")::Humanoid
		end
	end
	Player.CharacterAdded:Connect(Update); task.spawn(Update)
end

UserInputs:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
	if UserInputs.MouseBehavior.Name ~= "LockCenter" then
		Update:FireServer()
	end
end)

const RenderStepped = game.RunService.RenderStepped
while true do
	local DeltaTime = RenderStepped:Wait()
	
	if Character and Character:GetAttribute("SAMActive") then
		if UserInputs.MouseBehavior.Name == "LockCenter" then
			local Buffer = buffer.create(8) do
				local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Camera.CFrame.Rotation:GetComponents() do
					buffer.writef32(Buffer, 0, R02); R02 = nil
					buffer.writef32(Buffer, 4, R22); R22 = nil
				end
			end
			Update:FireServer(Buffer); Buffer = nil
		end
		if Humanoid then
			Humanoid.RootPart.AssemblyLinearVelocity = Humanoid.MoveDirection*Humanoid.WalkSpeed
		end
	end
	
	for GUID, IKControl in next, IKControls do
		IKControl.SmoothTime = DeltaTime
	end
end