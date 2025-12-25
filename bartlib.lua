-- Minimal, dependency-free Roblox GUI library (BartLib)

-- Usage:
-- local library = loadstring(game:HttpGet('<raw link to this file>'))()
-- local w = library:CreateWindow("barts Legacy")
-- local farming = w:CreateFolder("Farming")
-- farming:Toggle("autoClick", function(v) getgenv().autoClick = v if v then autoClick() end end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local theme = {
    Background = Color3.fromRGB(30, 30, 30),
    WindowAccent = Color3.fromRGB(10, 132, 255),
    FolderHeader = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(230, 230, 230),
    Subtext = Color3.fromRGB(180, 180, 180),
    Outline = Color3.fromRGB(20, 20, 20),
    Checked = Color3.fromRGB(102, 204, 102),
}

local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            inst.Parent = v
        else
            inst[k] = v
        end
    end
    return inst
end

local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            math.clamp(startPos.X.Scale + (delta.X / frame.Parent.AbsoluteSize.X), 0, 1 - frame.Size.X.Scale),
            startPos.X.Offset + delta.X,
            math.clamp(startPos.Y.Scale + (delta.Y / frame.Parent.AbsoluteSize.Y), 0, 1 - frame.Size.Y.Scale),
            startPos.Y.Offset + delta.Y
        )
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local Library = {}
Library.__index = Library

-- Create a single screengui container (one per library invocation)
local function makeScreenGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BartLib_" .. tostring(math.random(1000, 9999))
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = playerGui
    return sg
end

-- Constructor: return a library table (factory)
local function newLibrary()
    local self = setmetatable({}, Library)
    self._screenGui = makeScreenGui()
    return self
end

-- Create a new window/frame
function Library:CreateWindow(title)
    local screen = self._screenGui

    local window = new("Frame", {
        Name = "Window",
        Parent = screen,
        Size = UDim2.new(0, 380, 0, 420),
        Position = UDim2.new(0.5, -190, 0.5, -210),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Active = true,
    })

    local outline = new("Frame", {
        Name = "Outline",
        Parent = window,
        Size = UDim2.new(1, 2, 1, 2),
        Position = UDim2.new(0, -1, 0, -1),
        BackgroundColor3 = theme.Outline,
        BorderSizePixel = 0,
        ZIndex = 0,
    })

    local header = new("Frame", {
        Name = "Header",
        Parent = window,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = theme.WindowAccent,
        BorderSizePixel = 0,
    })
    local titleLabel = new("TextLabel", {
        Name = "Title",
        Parent = header,
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(title or "Window"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local closeBtn = new("TextButton", {
        Name = "Close",
        Parent = header,
        Size = UDim2.new(0, 28, 0, 18),
        Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(200, 60, 60),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    })
    closeBtn.MouseButton1Click:Connect(function()
        window.Visible = not window.Visible
    end)

    makeDraggable(window, header)

    local content = new("Frame", {
        Name = "Content",
        Parent = window,
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
    })
    local folderList = new("ScrollingFrame", {
        Name = "FolderList",
        Parent = content,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    local layout = new("UIListLayout", {
        Name = "UIListLayout",
        Parent = folderList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    local padding = new("UIPadding", {
        Name = "Padding",
        Parent = folderList,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })

    local win = {}
    win._root = window
    win._folders = {}

    function win:CreateFolder(name)
        local folderFrame = new("Frame", {
            Name = tostring(name),
            Parent = folderList,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = theme.FolderHeader,
            BorderSizePixel = 0,
        })
        local header = new("Frame", {
            Name = "FolderHeader",
            Parent = folderFrame,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
        })
        local lbl = new("TextLabel", {
            Name = "Label",
            Parent = header,
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Text = tostring(name),
            TextColor3 = theme.Text,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local toggleBtn = new("TextButton", {
            Name = "Toggle",
            Parent = header,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -22, 0.5, -9),
            Text = "-",
            TextColor3 = theme.Text,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            AutoButtonColor = false,
        })

        local contentFrame = new("Frame", {
            Name = "FolderContent",
            Parent = folderFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
        })
        local contentList = new("UIListLayout", {
            Name = "List",
            Parent = contentFrame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        local contentPad = new("UIPadding", {
            Name = "Padding",
            Parent = contentFrame,
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        })

        local expanded = true
        local function setExpanded(val)
            expanded = val
            toggleBtn.Text = expanded and "-" or "+"
            contentFrame.Size = expanded and UDim2.new(1, 0, 0, contentList.AbsoluteContentSize.Y + 8) or UDim2.new(1, 0, 0, 0)
            folderFrame.Size = UDim2.new(1, 0, 0, 30 + (expanded and (contentList.AbsoluteContentSize.Y + 8) or 0))
        end

        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if expanded then
                contentFrame.Size = UDim2.new(1, 0, 0, contentList.AbsoluteContentSize.Y + 8)
                folderFrame.Size = UDim2.new(1, 0, 0, 30 + (contentList.AbsoluteContentSize.Y + 8))
            end
        end)

        toggleBtn.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end)

        local folder = {
            _root = folderFrame,
            _content = contentFrame,
            _items = {},
        }

        -- Toggle: name, callback(value), [default = false]
        function folder:Toggle(name, callback, default)
            local item = new("Frame", {
                Name = tostring(name),
                Parent = contentFrame,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
            })
            local txt = new("TextLabel", {
                Name = "Text",
                Parent = item,
                Size = UDim2.new(1, -34, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                Text = tostring(name),
                TextColor3 = theme.Subtext,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local box = new("Frame", {
                Name = "Box",
                Parent = item,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -28, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0),
            })
            local tick = new("Frame", {
                Name = "Tick",
                Parent = box,
                Size = UDim2.new(1, -6, 1, -6),
                Position = UDim2.new(0, 3, 0, 3),
                BackgroundColor3 = theme.Checked,
                Visible = false,
                BorderSizePixel = 0,
            })
            local btn = new("TextButton", {
                Name = "Btn",
                Parent = item,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
            })

            local state = default and true or false
            tick.Visible = state

            local function setState(v)
                state = v and true or false
                tick.Visible = state
                -- simple feedback animation
                TweenService:Create(box, TweenInfo.new(0.12), {BackgroundColor3 = state and Color3.fromRGB(46, 46, 46) or Color3.fromRGB(60, 60, 60)}):Play()
                -- call provided callback safely
                if typeof(callback) == "function" then
                    local ok, err = pcall(callback, state)
                    if not ok then
                        warn("BartLib callback error:", err)
                    end
                end
            end

            btn.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            -- store and return control
            folder._items[name] = {
                _set = setState,
                _state = function() return state end,
            }
            return {
                Set = function(_, v) setState(tonumber(v) == 1 or v == true) end,
                Get = function() return state end,
            }
        end

        win._folders[name] = folder
        return folder
    end

    return win
end

-- Return a callable library instance
local function create()
    return newLibrary()
end

return create()