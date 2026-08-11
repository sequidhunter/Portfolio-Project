--!strict

--Services
local Players = game:GetService("Players")

local HTTPService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--Place your webhook here.
local ReportWebhook = ""


--Finds or creates a "Report" remote event. Can be easily replaced with a pre-existing one.
local ReportEvent = ReplicatedStorage:FindFirstChild("ReportEvent") or Instance.new("RemoteEvent")
ReportEvent.Name = "ReportEvent"
ReportEvent.Parent = ReplicatedStorage

local Types = require(script.Types)

local ReportManager = {}

--Colors for the reports.
local ReportColors = {

	["Cheating"] = tonumber(16732240),
	["Griefing"] = tonumber(16767280),
	["Inappropriate Avatar"] = tonumber(16734753),
	["Toxicity"] = tonumber(16734753),

}

--Gets an image link to send to the report, (Used for the thumbnail of the author.)
local function GetUserIcon(userId : number)
	local icon_url = "https://thumbnails.roproxy.com/v1/users/avatar-bust?userIds=" .. userId .. "&size=100x100&format=Png&isCircular=true"
	local response = HTTPService:GetAsync(icon_url)
	local icon_data = HTTPService:JSONDecode(response)

	--Returns the imageUrl from the table in "data"
	return icon_data["data"][1]["imageUrl"]
end

--This function sends the report to the desired webhook.
local function SendReportWebhook(reporter : Player, reported : number, reason : string, note : string)
	
	--Shows a warning, but this function does in fact work with the normal UserIds.
	local reportedPlayer = Players:GetPlayerByUserId(reported)

	local reporter_icon_url = GetUserIcon(reporter.UserId)
	
	local reported_icon_url = GetUserIcon(reported)

	--Json for the report, uses embeds for discord
	local finalReport = {
		embeds = {{
			["author"] = {
				name = ("@"..reporter.Name.."("..reporter.DisplayName..")");
				icon_url = reporter_icon_url;
				url = "https://www.roblox.com/users/"..reporter.UserId;
			},
			title = "Report Information",
			type = "rich",
			color = ReportColors[reason],
			thumbnail = {url = reported_icon_url},

			fields = {
				{
					name = "Name",
					value = ("@"..reportedPlayer.Name.."("..reportedPlayer.DisplayName..")"),
					inline = true,
				},
				{
					name = "Reason",
					value = (reason),
					inline = true,
				},
				{
					name = "Profile",
					value = ("https://www.roblox.com/users/"..reported),
					inline = false,
				},
				{
					name = "Additional Note",
					value = (note),
					inline = false,
				},



			},
			timestamp = DateTime.now():ToIsoDate()
		}}
	}

	local json = HTTPService:JSONEncode(finalReport)
	return HTTPService:PostAsync(ReportWebhook,json)
end


local function OnClientReport(player : Player, Report : Types.Report)
	if type(Report) ~= "table" then return end

	local user = Report.User
	local reason = Report.Reason
	local note = Report.AdditionalNote

	if type(reason) ~= "string" or type(note) ~= "string" then return end
	SendReportWebhook(player, user, reason, note) 
end

function ReportManager.init()

	ReportEvent.OnServerEvent:Connect(OnClientReport)
end

return ReportManager
