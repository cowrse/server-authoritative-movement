--// Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Constants
local Remote = ReplicatedStorage:WaitForChild("Settings")
local UI = script.Parent

--// Main
UI.Enabled = true

-- Walkspeed
local WalkspeedFrame = UI.Walkspeed
WalkspeedFrame.FocusLost:Connect(function()
	local Result = tonumber(WalkspeedFrame.Text)
	if not Result then
		Result = 16
		WalkspeedFrame.Text = Result
	end
	
	local Buffer = buffer.create(8) do
		buffer.writef32(Buffer, 0, 0)
		buffer.writef32(Buffer, 4, Result)
	end
	Remote:FireServer(Buffer); Buffer = nil
end)

-- Jump Power
local JumpPowerFrame = UI.JumpPower
JumpPowerFrame.FocusLost:Connect(function()
	local Result = tonumber(JumpPowerFrame.Text)
	if not Result then
		Result = 50
		JumpPowerFrame.Text = Result
	end

	local Buffer = buffer.create(8) do
		buffer.writef32(Buffer, 0, 1)
		buffer.writef32(Buffer, 4, Result)
	end
	Remote:FireServer(Buffer); Buffer = nil
end)

-- Toggle SAM
local SAMActiveFrame = UI.SAMActive
SAMActiveFrame.Activated:Connect(function()
	local Buffer = buffer.create(8) do
		buffer.writef32(Buffer, 0, 2)
		buffer.writef32(Buffer, 4, 0)
	end
	Remote:FireServer(Buffer); Buffer = nil
end)