local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local theme = {
    Bg = Color3.fromRGB(20,20,22),
    Accent = Color3.fromRGB(45,45,48),
    Tab = Color3.fromRGB(36,36,39),
    Panel = Color3.fromRGB(30,30,32),
    Text = Color3.fromRGB(235,235,235),
    Sub = Color3.fromRGB(170,170,170),
    Checked = Color3.fromRGB(75,209,239),
    Button = Color3.fromRGB(60,60,60),
    Slider = Color3.fromRGB(75,209,239),
    Outline = Color3.fromRGB(10,10,10),
}

local function new(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k == "Parent" then inst.Parent = v else inst[k] = v end
    end
    return inst
end

-- Smooth, reliable dragging using global input + RenderStepped and a deadzone
local function makeDraggable(frame, handle)
    handle = handle or frame
    handle.Active = true
    local dragging, dragStart, startPos, startedMoving, clickOffset
    local renderConn

    -- start drag when clicking the handle (works reliably for header + its children)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        startedMoving = false
        -- capture exact mouse and frame positions and the click offset
        dragStart = UserInputService:GetMouseLocation()
        startPos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
        clickOffset = dragStart - startPos

        renderConn = RunService.RenderStepped:Connect(function()
            if not dragging then return end
            local m = UserInputService:GetMouseLocation()
            local newPos = m - clickOffset
            local delta = newPos - startPos
            if not startedMoving then
                if math.abs(delta.X) + math.abs(delta.Y) < 6 then return end
                startedMoving = true
            end
            local parentSize = frame.Parent.AbsoluteSize
            local frameSize = frame.AbsoluteSize
            local newX = math.clamp(newPos.X, 0, parentSize.X - frameSize.X)
            local newY = math.clamp(newPos.Y, 0, parentSize.Y - frameSize.Y)
            frame.Position = UDim2.new(0, newX, 0, newY)
        end)
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if renderConn then renderConn:Disconnect(); renderConn = nil end
        end
    end)
end

local BartLib = {}
BartLib.__index = BartLib

function BartLib:CreateWindow(title)
    local self = {}
    self._folders = {}
    self._minimized = false

    local SCREEN = new("ScreenGui", { Name = "bartlib_install_"..tostring(math.random(1000,9999)), ResetOnSpawn = false, IgnoreGuiInset = true, Parent = playerGui })

    local WIDTH = 420
    local HEADER_H = 34
    local TAB_H = 36
    local MAX_H = 360
    local CONTENT_PADDING = 24

    local win = new("Frame", {
        Parent = SCREEN,
        Name = "Window",
        Size = UDim2.new(0, WIDTH, 0, HEADER_H),
        Position = UDim2.new(0.5, -WIDTH/2, 0, 12),
        BackgroundColor3 = theme.Bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
    })
    new("UICorner", { Parent = win, CornerRadius = UDim.new(0,8) })
    new("Frame", { Parent = win, Size = UDim2.new(1,2,1,2), Position = UDim2.new(0,-1,0,-1), BackgroundColor3 = theme.Outline, BorderSizePixel = 0, ZIndex = 0 })

    local header = new("Frame", { Parent = win, Size = UDim2.new(1,0,0,HEADER_H), BackgroundColor3 = theme.Accent, BorderSizePixel = 0 })
    new("UICorner", { Parent = header, CornerRadius = UDim.new(0,8) })
    new("TextLabel", { Parent = header, Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = tostring(title or "Window"), TextColor3 = theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local miniBtn = new("TextButton", { Parent = header, Size = UDim2.new(0,36,0,22), Position = UDim2.new(1, -44, 0.5, -11), BackgroundColor3 = theme.Tab, Text = "—", TextColor3 = theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false })
    new("UICorner", { Parent = miniBtn, CornerRadius = UDim.new(0,6) })

    local tabBar = new("Frame", { Parent = win, Name = "TabBar", Position = UDim2.new(0,0,0,HEADER_H), Size = UDim2.new(1,0,0,TAB_H), BackgroundColor3 = theme.Tab, BorderSizePixel = 0, ClipsDescendants = false })
    new("UICorner", { Parent = tabBar, CornerRadius = UDim.new(0,6) })
    new("UIListLayout", { Parent = tabBar, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder })
    new("UIPadding", { Parent = tabBar, PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) })

    local content = new("Frame", { Parent = win, Position = UDim2.new(0,0,0, HEADER_H + TAB_H), Size = UDim2.new(1,0,0,0), BackgroundColor3 = theme.Panel, BorderSizePixel = 0 })
    new("UIListLayout", { Parent = content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })
    new("UIPadding", { Parent = content, PaddingLeft = UDim.new(0,8), PaddingTop = UDim.new(0,8), PaddingRight = UDim.new(0,8) })

    makeDraggable(win, header)

    local function setMinimized(m)
        self._minimized = m and true or false
        if self._minimized then
            miniBtn.Text = "+"
            win:TweenSize(UDim2.new(0, WIDTH, 0, HEADER_H), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            tabBar.Visible = false
            content.Visible = false
            for _,f in ipairs(self._folders) do f.ElementsFrame.Visible = false end
        else
            miniBtn.Text = "—"
            tabBar.Visible = true
            content.Visible = true
            -- prefer sizing to the currently selected folder (if any)
            local selected
            for _,f in ipairs(self._folders) do if f.ElementsFrame.Visible then selected = f; break end end

            -- wait one frame so UIListLayout updates sizes then compute the target size
            task.defer(function()
                RunService.Heartbeat:Wait()
                local targetHeight = 0
                if selected then
                    local h = (selected._uiList and selected._uiList.AbsoluteContentSize.Y) or selected.ElementsFrame.AbsoluteSize.Y
                    targetHeight = math.clamp(HEADER_H + TAB_H + h + CONTENT_PADDING, HEADER_H + TAB_H + 80, MAX_H)
                else
                    local maxContent = 0
                    for _,f in ipairs(self._folders) do
                        local h = (f._uiList and f._uiList.AbsoluteContentSize.Y) or f.ElementsFrame.AbsoluteSize.Y
                        maxContent = math.max(maxContent, h)
                    end
                    targetHeight = math.clamp(HEADER_H + TAB_H + maxContent + CONTENT_PADDING, HEADER_H + TAB_H + 80, MAX_H)
                end
                win:TweenSize(UDim2.new(0, WIDTH, 0, targetHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end)
        end
    end
    miniBtn.MouseButton1Click:Connect(function() setMinimized(not self._minimized) end)

    local function selectFolder(folder)
        if not folder then return end
        for _,f in ipairs(self._folders) do
            f.ElementsFrame.Visible = (f == folder)
            f.Tab.Button.BackgroundColor3 = (f == folder) and theme.Accent or theme.Tab
        end
        if self._minimized then setMinimized(false) end

        local function measure()
            local listY = (folder._uiList and folder._uiList.AbsoluteContentSize.Y) or folder.ElementsFrame.AbsoluteSize.Y
            if listY == 0 and #folder.Elements > 0 then
                RunService.Heartbeat:Wait()
                listY = (folder._uiList and folder._uiList.AbsoluteContentSize.Y) or folder.ElementsFrame.AbsoluteSize.Y
            end
            return math.min(MAX_H - (HEADER_H + TAB_H), listY)
        end

        local contentH = measure()
        local desired = HEADER_H + TAB_H + math.max(60, contentH) + CONTENT_PADDING
        win:TweenSize(UDim2.new(0, WIDTH, 0, desired), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
    end

    function self:CreateFolder(name)
        local folder = { Name = name, Elements = {}, Opened = false }
        local idx = #self._folders + 1

        local tabBtn = new("TextButton", { Parent = tabBar, Name = "Tab_"..idx, BackgroundColor3 = theme.Tab, AutoButtonColor = false, Text = name or ("Tab"..idx), TextColor3 = theme.Text, Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(0,0,0,28), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = idx })
        new("UICorner", { Parent = tabBtn, CornerRadius = UDim.new(0,6) })
        new("UIPadding", { Parent = tabBtn, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12) })
        tabBtn.MouseButton1Click:Connect(function() selectFolder(folder) end)

        local elems = new("Frame", { Parent = content, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = false, LayoutOrder = idx })
        local uiList = new("UIListLayout", { Parent = elems, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })
        new("UIPadding", { Parent = elems, PaddingLeft = UDim.new(0,6), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6) })
        folder._uiList = uiList
        uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() elems.Size = UDim2.new(1,0,0, uiList.AbsoluteContentSize.Y) end)

        local function AddToggle(label, callback, default)
            local item = new("Frame", { Parent = elems, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1 })
            new("TextLabel", { Parent = item, Size = UDim2.new(0.75, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Text = label, TextColor3 = theme.Sub, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
            local box = new("Frame", { Parent = item, Size = UDim2.new(0,20,0,20), Position = UDim2.new(1, -28, 0.5, -10), BackgroundColor3 = Color3.fromRGB(50,50,50), BorderSizePixel = 0 })
            new("UICorner", { Parent = box, CornerRadius = UDim.new(0,4) })
            local tick = new("Frame", { Parent = box, Size = UDim2.new(1, -6, 1, -6), Position = UDim2.new(0,3,0,3), BackgroundColor3 = theme.Checked, Visible = default and true or false, BorderSizePixel = 0 })
            new("UICorner", { Parent = tick, CornerRadius = UDim.new(0,3) })
            local btn = new("TextButton", { Parent = item, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "", AutoButtonColor = false })
            local state = default and true or false
            local function set(v) state = not not v; tick.Visible = state; pcall(function() if type(callback) == "function" then callback(state) end end) end
            btn.MouseButton1Click:Connect(function() set(not state) end)
            table.insert(folder.Elements, { Type = "Toggle", Set = set, Get = function() return state end })
            return { Set = set, Get = function() return state end }
        end

        local function AddButton(label, cb)
            local b = new("TextButton", { Parent = elems, Size = UDim2.new(1,0,0,28), BackgroundColor3 = theme.Button, Text = label, TextColor3 = theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false })
            b.TextXAlignment = Enum.TextXAlignment.Left
            new("UICorner", { Parent = b, CornerRadius = UDim.new(0,6) })
            new("UIPadding", { Parent = b, PaddingLeft = UDim.new(0,8) })
            b.MouseButton1Click:Connect(function() pcall(cb) end)
            table.insert(folder.Elements, { Type = "Button", Btn = b })
            return b
        end

        local function AddSlider(label, opts, cb)
            local min = opts and opts.min or 0
            local max = opts and opts.max or 100
            local precise = opts and opts.precise
            local step = (opts and opts.step) or (precise and 0.01) or 1
            local f = new("Frame", { Parent = elems, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1 })
            new("TextLabel", { Parent = f, Size = UDim2.new(0.55,0,0,18), Position = UDim2.new(0,8,0,4), BackgroundTransparency = 1, Text = label, TextColor3 = theme.Sub, Font = Enum.Font.SourceSans, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            local valLbl = new("TextLabel", { Parent = f, Size = UDim2.new(0.3,0,0,18), Position = UDim2.new(1,-120,0,4), BackgroundTransparency = 1, Text = tostring(min), TextColor3 = theme.Text, Font = Enum.Font.SourceSans, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
            local track = new("Frame", { Parent = f, Size = UDim2.new(1,-140,0,10), Position = UDim2.new(0,8,0,20), BackgroundColor3 = Color3.fromRGB(60,60,60) })
            new("UICorner", { Parent = track, CornerRadius = UDim.new(0,4) })
            local fill = new("Frame", { Parent = track, Size = UDim2.new(0,0,1,0), BackgroundColor3 = theme.Slider })
            new("UICorner", { Parent = fill, CornerRadius = UDim.new(0,4) })
            local dragging = false
            local value = min
            local function formatValue(v)
                if step < 1 then
                    return string.format("%.2f", v)
                else
                    return tostring(math.floor(v + 0.5))
                end
            end
            local function setFromX(x)
                local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
                local raw = (min + (max-min)*rel)
                value = math.floor(raw/step + 0.5) * step
                fill.Size = UDim2.new(math.clamp((value - min)/(max - min), 0, 1),0,1,0)
                valLbl.Text = formatValue(value)
                if cb then pcall(cb, value) end
            end
            -- initialize visuals to min/default
            do
                local initRel = (value - min) / math.max(1, (max - min))
                fill.Size = UDim2.new(math.clamp(initRel, 0, 1), 0, 1, 0)
                valLbl.Text = formatValue(value)
            end
            track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setFromX(i.Position.X) end end)
            track.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end end)
            table.insert(folder.Elements, { Type = "Slider", Frame = f })
            return f
        end

        local function AddDropdown(label, options, multi, cb)
            local container = new("Frame", { Parent = elems, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1 })
            local main = new("TextButton", { Parent = container, Size = UDim2.new(1,0,0,30), BackgroundColor3 = theme.Button, Text = label, TextColor3 = theme.Text, AutoButtonColor = false })
            main.TextXAlignment = Enum.TextXAlignment.Left
            new("UICorner", { Parent = main, CornerRadius = UDim.new(0,6) })
            new("UIPadding", { Parent = main, PaddingLeft = UDim.new(0,8) })
            local list = new("Frame", { Parent = elems, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = false })
            local listLayout = new("UIListLayout", { Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
            new("UIPadding", { Parent = list, PaddingLeft = UDim.new(0,8), PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4) })
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.Size = UDim2.new(1,0,0, listLayout.AbsoluteContentSize.Y) end)
            main.MouseButton1Click:Connect(function()
                list.Visible = not list.Visible
                if list.Visible and self._minimized then setMinimized(false) end
                -- always re-measure after toggle (open or close) so window expands/shrinks
                task.defer(function() RunService.Heartbeat:Wait(); selectFolder(folder) end)
            end)
            for _,opt in ipairs(options or {}) do
                local o = new("TextButton", { Parent = list, Size = UDim2.new(1,0,0,26), BackgroundColor3 = theme.Button, Text = opt, TextColor3 = theme.Text, AutoButtonColor = false })
                o.TextXAlignment = Enum.TextXAlignment.Left
                new("UICorner", { Parent = o, CornerRadius = UDim.new(0,6) })
                new("UIPadding", { Parent = o, PaddingLeft = UDim.new(0,8) })
                o.MouseButton1Click:Connect(function()
                    main.Text = tostring(opt)
                    list.Visible = false
                    if cb then pcall(cb, opt) end
                    -- ensure window resizes to reflect the closed list
                    task.defer(function() RunService.Heartbeat:Wait(); selectFolder(folder) end)
                end)
            end
            table.insert(folder.Elements, { Type = "Dropdown", Frame = container })
            return container
        end

        local function AddBind(label, keyDefault, cb)
            local f = new("Frame", { Parent = elems, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1 })
            new("TextLabel", { Parent = f, Size = UDim2.new(0.65,0,1,0), BackgroundTransparency = 1, Text = label, TextColor3 = theme.Sub, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,8,0,0) })
            local kb = new("TextButton", { Parent = f, Size = UDim2.new(0,80,0,20), Position = UDim2.new(1,-88,0.5,-10), BackgroundColor3 = theme.Button, Text = (keyDefault and tostring(keyDefault):gsub("Enum.KeyCode.","") or "None"), AutoButtonColor = false })
            new("UICorner", { Parent = kb, CornerRadius = UDim.new(0,6) })
            kb.MouseButton1Click:Connect(function()
                kb.Text = "Press..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        kb.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.","")
                        if cb then pcall(cb, input.KeyCode) end
                        conn:Disconnect()
                    end
                end)
            end)
            table.insert(folder.Elements, { Type = "Bind", Frame = f })
            return f
        end

        local function AddBox(label, typ, cb)
            local b = new("TextBox", { Parent = elems, Size = UDim2.new(1,0,0,28), BackgroundColor3 = theme.Button, Text = (type(label)=="string" and label or ""), TextColor3 = theme.Text, Font = Enum.Font.SourceSans, TextSize = 14 })
            new("UICorner", { Parent = b, CornerRadius = UDim.new(0,6) })
            b.FocusLost:Connect(function(enter)
                if enter and cb then pcall(cb, b.Text) end
            end)
            table.insert(folder.Elements, { Type = "Box", Box = b })
            return b
        end

        -- public API supports colon and dot call styles
        folder.Tab = { Button = tabBtn }
        folder.ElementsFrame = elems
        folder.Toggle = function(_, ...) return AddToggle(...) end
        folder.Button = function(_, ...) return AddButton(...) end
        folder.Slider = function(_, ...) return AddSlider(...) end
        folder.Dropdown = function(_, ...) return AddDropdown(...) end
        folder.Bind = function(_, ...) return AddBind(...) end
        folder.Box = function(_, ...) return AddBox(...) end
        folder.Open = function() selectFolder(folder) end
        folder.Close = function() elems.Visible = false; task.defer(function() RunService.Heartbeat:Wait(); selectFolder(folder) end) end

        table.insert(self._folders, folder)
        if #self._folders == 1 then selectFolder(folder) end
        return folder
    end

    function self:ToggleUI() setMinimized(not self._minimized) end
    function self:DestroyGui() if SCREEN then SCREEN:Destroy() end end

    return setmetatable(self, { __index = BartLib })
end

-- return the library (also callable for compatibility)
setmetatable(BartLib, { __call = function() return BartLib end })
return BartLib