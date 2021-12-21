local UI = script.Parent
local Title = UI.Background.Title
local GameU = UI.Background.Game

local ComboBar = GameU.Combo.Bar.Value
local Highscore = GameU.Scores.Highscore.Value
local Score = GameU.Scores.Score.Value
local Time = GameU.Scores.Time.Value
local DataStoreService = game:GetService("DataStoreService")

local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local InGame = false

local Sounds = game:GetService("SoundService")
local Error = Sounds.Error
local ScoreSound = Sounds.Score
local Completed = false
local ComboValue = 0
local CurrentMode = "None"

local TweenService = game:GetService("TweenService")

local ScoreList = {}

local Blacks = 0
local BlacksLists = {}

local Highscores = {
	["Frenzy"] = 0,
	["Pattern"] = 0,
	["Endurance"] = 0
}



function ResetTiles()
	Blacks = 0
	for i,v in next, GameU.Tiles:GetChildren() do
		v.BackgroundColor3 = Color3.new(255,255,255)
	end
end

function EndGame(Completed)
	if Completed then
		GameU.Result.TextColor3 = Color3.new(0, 0, 0)
		if CurrentMode == "Frenzy" then
			GameU.Result.Text = "Times Up"
		elseif CurrentMode == "Pattern" then
			GameU.Result.Text = "Finished!"
		end
	else
		GameU.Result.Text = "Fail"
		GameU.Result.TextColor3 = Color3.new(255, 0, 0)
	end

	for i = 0, 10, 1 do
		GameU.Result.Visible = true
		wait(.1)
		GameU.Result.Visible = false
		wait(.1)
	end

	local Date = DateTime.now()

	local ScoreInfo = {Tick = os.time(), Score = tonumber(Score.Text)}

	table.insert(ScoreList, ScoreInfo)

	UI.Background.Leaderboard.CurrentScore.Text = "You scored " .. Score.Text
	UI.Background.Leaderboard.Visible = true

	GameU.Visible = false
	Title.Visible = true
end

function CreateBlack(Number)
	local Tile = GameU.Tiles[tostring(Number)]
	if BlacksLists[Number] == nil then
		local TweenHappening = true

		local H = Instance.new("NumberValue")
		H.Value = 0

		spawn(function()
			while wait() and TweenHappening do
				Tile.BackgroundColor3 = Color3.fromRGB(255 - H.Value, 255 - H.Value, 255 - H.Value)
			end
		end)

		local X = TweenService:Create(H, TweenInfo.new(.3), {Value = 255})
		X.Completed:Connect(function()
			TweenHappening = false
		end)
		X:Play()
		BlacksLists[Number] = "Black"
		Blacks = Blacks + 1
	end
end

function StartTimer(Start, Increment)
	GameU.Result.TextColor3 = Color3.new(1, 0.917647, 0)
	for i = 3, 1, -1 do
		GameU.Result.Visible = true
		GameU.Result.Text = i
		wait(1)
	end
	GameU.Result.Text = "Go!"

	GameU.Result.Visible = false
	InGame = true
	Time.Text = Start

	spawn(function()
		while wait(math.abs(Increment)) and InGame do
			Start = Start + Increment
			Time.Text = Start
			if Start == 0 then
				Completed = true
				InGame = false
			end
		end
	end)
end

function AddScore()
	if CurrentMode ~= "Pattern" and CurrentMode ~= "Endurance" then
		local Add = 1
		Add = math.ceil(ComboValue/100)
		Score.Text = tonumber(Score.Text) + Add
		Score.TextColor3 = Color3.new(0, 255, 0)
		Score.TextScaled = true
		wait(.05)
		Score.TextScaled = false
		Score.TextColor3 = Color3.fromRGB(55, 212, 255)
	elseif CurrentMode == "Endurance" then
		local Add = 1
		Score.Text = tonumber(Score.Text) + Add
		Score.TextColor3 = Color3.new(0, 255, 0)
		Score.TextScaled = true
		wait(.05)
		Score.TextScaled = false
		Score.TextColor3 = Color3.fromRGB(55, 212, 255)
	end
end

function InitFrenzy()
	CurrentMode = "Frenzy"
	Time.Text = "30"
	Highscore.Text = Highscores["Frenzy"]

	Completed = false

	StartTimer(30, -1)

	while InGame and task.wait() do
		if Blacks < 4 then
			repeat
				local Number = math.random(1, 16)
				if GameU.Tiles[tostring(Number)].BackgroundColor3 == Color3.new(255, 255, 255) then
					CreateBlack(Number)
				end
			until Blacks >= 4
		end
	end

	EndGame(Completed)
end

function InitEndurance()
	CurrentMode = "Endurance"
	Highscore.Text = Highscores["Endurance"]
	Time.Text = "10"

	Completed = false

	local MilestoneReached = 0

	local Start = 10

	GameU.Result.TextColor3 = Color3.new(1, 0.917647, 0)
	for i = 3, 1, -1 do
		GameU.Result.Visible = true
		GameU.Result.Text = i
		wait(.3)
	end
	GameU.Result.Text = "Go!"

	GameU.Result.Visible = false
	InGame = true
	Time.Text = Start

	spawn(function()
		while wait(1) and InGame do
			Start = Start - 1
			Time.Text = Start
			if Start == 0 then
				Completed = true
				InGame = false
			end
		end
	end)

	while InGame and task.wait() do
		if tonumber(Score.Text) % 40 == 0 and tonumber(Score.Text) > MilestoneReached then
			MilestoneReached = tonumber(Score.Text)
			Start = Start + 10
			print(MilestoneReached)
			spawn(function()
				GameU.Result.TextColor3 = Color3.new(0, 0, 0)
				GameU.Result.Text = "+10 Seconds"
				GameU.Result.Visible = true
				wait(.3)
				GameU.Result.Visible = false
			end)
		end
		if Blacks < 3 then
			repeat
				local Number = math.random(1, 16)
				if GameU.Tiles[tostring(Number)].BackgroundColor3 == Color3.new(255, 255, 255) then
					CreateBlack(Number)
				end
			until Blacks >= 3
		end
	end

	EndGame(Completed)
end

function InitPattern()
	Highscore.Text = Highscores["Pattern"]
	CurrentMode = "Pattern"
	Time.Text = "0"

	Completed = false

	local PatternsSolved = 0

	StartTimer(0, .01)

	while InGame and task.wait() do
		if Blacks <= 0 then
			PatternsSolved = PatternsSolved + 1
			Score.Text = Time.Text
			repeat
				local Number = math.random(1, 16)
				if GameU.Tiles[tostring(Number)].BackgroundColor3 ~= Color3.new(0, 0, 0) then
					CreateBlack(Number)
				end
				wait()
			until Blacks >= 4
		end

		if PatternsSolved >= 15 then
			InGame = false
			Completed = true
		end
	end
	
	if PatternsSolved < 15 then
		Score.Text = -1
	end

	EndGame(Completed)
end

local Buttons = {
	["Frenzy"] = InitFrenzy,
	["Endurance"] = InitEndurance,
	["Pattern"] = InitPattern
}

for i,v in next, Title:GetChildren() do
	coroutine.wrap(function()
		if v:IsA("TextButton") then
			v.MouseButton1Click:Connect(function()
				if not InGame then
					local Highest = 0 
					do
						for Idx, Score in next, ScoreList do
							if Score.Score >= Highest then
								Highest = Score.Score
							end
						end
					end
					Highscore.Text = Highest
					Score.Text = "0"
					ResetTiles()
					GameU.Visible = true
					Title.Visible = false
					Buttons[v.Name]()
					CurrentMode = v.Name
				end
			end)
		end
	end)()
end

for i,v in next, GameU.Tiles:GetChildren() do
	v.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and InGame then
			if v.BackgroundColor3 == Color3.new(255, 255, 255) then
				Error.TimePosition = 0
				Error:Play()
				InGame = false
				v.BackgroundColor3 = Color3.new(255, 0, 0)
			else
				AddScore()
				ScoreSound.TimePosition = 0
				ScoreSound:Play()
				Blacks = Blacks - 1
				ComboValue = ComboValue + 45
				spawn(function()
					v.BackgroundColor3 = Color3.new(0,255,0)
					local TemptText = Instance.new("TextLabel")
					TemptText.Size = UDim2.new(1,0,1,0)
					TemptText.BackgroundTransparency = 1
					if CurrentMode == "Frenzy" then
						TemptText.Text = "+ "..math.ceil(ComboValue/100)
					else
						TemptText.Text = "+ " .. 1
					end
					TemptText.Parent = v
					wait(.1)
					TemptText:Destroy()
					v.BackgroundColor3 = Color3.new(255, 255, 255)
				end)
				BlacksLists[tonumber(v.Name)] = nil
			end
		end

	end)
end

spawn(function()
	while wait() do
		ComboValue = math.clamp(ComboValue - 5, 0, 500)
		ComboBar.Size = UDim2.new(0, ComboValue, 1, 0)
	end
end)

UI.Background.Leaderboard.Back.MouseButton1Click:Connect(function()
	UI.Background.Leaderboard.Visible = false
end)
