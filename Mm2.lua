--[[ luxxs v4.3 | by DrHub | MM2 ]]
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local HttpService=game:GetService("HttpService")
local Workspace=game:GetService("Workspace")
local VU=game:GetService("VirtualUser")
local StatsSvc=game:GetService("Stats")
local LP=Players.LocalPlayer
local mouse=LP:GetMouse()

local FOLDER="luxxs"
local VALID_KEYS={["ludr"]=true}
local hasFS=type(writefile)=="function" and type(readfile)=="function" and type(isfile)=="function"
local function ensureFolder()
    if type(makefolder)=="function" and type(isfolder)=="function" and not isfolder(FOLDER) then pcall(makefolder,FOLDER) end
end

-- =====================================================================
-- THEME
-- =====================================================================
local ACCENTS={
    Green=Color3.fromRGB(86,255,126),Lime=Color3.fromRGB(196,255,61),Ice=Color3.fromRGB(110,214,255),
    Violet=Color3.fromRGB(158,110,255),Gold=Color3.fromRGB(255,196,70),Rose=Color3.fromRGB(255,96,160),Coral=Color3.fromRGB(255,104,84),
}
local ACCENT_NAMES={"Green","Lime","Ice","Violet","Gold","Rose","Coral"}
local ACC_NAME="Green"
if hasFS then
    pcall(function()
        local p=FOLDER.."/accent.txt"
        if isfile(p) then local n=readfile(p); if ACCENTS[n] then ACC_NAME=n end end
    end)
end
local ACC=ACCENTS[ACC_NAME]

local C={
    bg=Color3.fromRGB(10,12,11),panel=Color3.fromRGB(15,18,16),row=Color3.fromRGB(24,29,26),line=Color3.fromRGB(38,46,41),
    off=Color3.fromRGB(56,64,60),text=Color3.fromRGB(232,238,233),dim=Color3.fromRGB(120,134,126),red=Color3.fromRGB(255,84,84),
}
local WHITE=Color3.fromRGB(255,255,255)
local BODY_GRAY=Color3.fromRGB(196,196,206)
local F_HEAD,F_BODY,F_MONO,F_SEC=Enum.Font.Michroma,Enum.Font.SourceSansSemibold,Enum.Font.RobotoMono,Enum.Font.Oswald
local ROLE_COLORS={Murderer=Color3.fromRGB(255,60,60),Sheriff=Color3.fromRGB(70,130,255),Innocent=Color3.fromRGB(70,230,110)}

local G={alpha=0,size=1}
local themed,bgReg={},{}
local function T(o,p,fn)
    themed[#themed+1]={o,p,fn}
    o[p]=fn and fn(ACC) or ACC
end
local function setAccent(c)
    ACC=c
    for _,t in ipairs(themed) do
        pcall(function() t[1][t[2]]=t[3] and t[3](ACC) or ACC end)
    end
end
local function BG(o,base)
    bgReg[#bgReg+1]={o,base}
    o.BackgroundTransparency=math.clamp(base+G.alpha,0,1)
    return o
end
local function applyAlpha()
    for _,r in ipairs(bgReg) do
        if r[1].Parent then r[1].BackgroundTransparency=math.clamp(r[2]+G.alpha,0,1) end
    end
end

local connections={}
local function track(c) connections[#connections+1]=c; return c end
local function tween(o,ti,p,s,d)
    local tw=TweenService:Create(o,TweenInfo.new(ti,s or Enum.EasingStyle.Quint,d or Enum.EasingDirection.Out),p)
    tw:Play()
    return tw
end
local function new(cls,props)
    local o=Instance.new(cls)
    for k,v in pairs(props) do if k~="Parent" then o[k]=v end end
    o.Parent=props.Parent
    return o
end
local function corner(o,r) return new("UICorner",{CornerRadius=UDim.new(0,r),Parent=o}) end
local function stroke(o,col,th,tr)
    return new("UIStroke",{Color=col,Thickness=th or 1,Transparency=tr or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=o})
end
local function gradient(f,rot,seq,tseq)
    local g=new("UIGradient",{Rotation=rot or 0,Parent=f})
    if seq then g.Color=seq end
    if tseq then g.Transparency=tseq end
    return g
end
local function cornerTick(parent,x,y,dx,dy,len,z)
    local h=new("Frame",{BorderSizePixel=0,Size=UDim2.fromOffset(len,1),Position=UDim2.fromOffset(dx>0 and x or x-len,dy>0 and y or y-1),ZIndex=z or 5,Parent=parent}); T(h,"BackgroundColor3")
    local v=new("Frame",{BorderSizePixel=0,Size=UDim2.fromOffset(1,len),Position=UDim2.fromOffset(dx>0 and x or x-1,dy>0 and y or y-len),ZIndex=z or 5,Parent=parent}); T(v,"BackgroundColor3")
end
local function setLine(f,x1,y1,x2,y2,th,col)
    local dx,dy=x2-x1,y2-y1
    f.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),th)
    f.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2)
    f.Rotation=math.deg(math.atan2(dy,dx))
    if col then f.BackgroundColor3=col end
    f.Visible=true
end

-- colors are stored as {h,s,v,rb} tables so they save to JSON and support shades
local function hsvOf(c) local h,s,v=c:ToHSV(); return {h=h,s=s,v=v,rb=false} end
local function colorOf(c,t,off)
    if type(c)~="table" then return ACC end
    if c.rb then return Color3.fromHSV(((t or os.clock())*0.2+(off or 0))%1,math.max(c.s,0.5),math.max(c.v,0.6)) end
    return Color3.fromHSV(c.h,c.s,c.v)
end
local function copyColor(c) return {h=c.h,s=c.s,v=c.v,rb=c.rb and true or false} end

local Flags,Setters,Defaults={},{},{}
local function register(k,d,s) Flags[k]=d; Defaults[k]=d; Setters[k]=s end

-- =====================================================================
-- GUI ROOTS
-- =====================================================================
local okP,parentGui=pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
if not okP or not parentGui then parentGui=LP:WaitForChild("PlayerGui") end
for _,par in ipairs({parentGui,LP:WaitForChild("PlayerGui")}) do
    for _,n in ipairs({"luxxs","luxxsKey","luxxsESP","luxxsFPS"}) do
        local o=par:FindFirstChild(n)
        if o then o:Destroy() end
    end
end
local function mkGui(name,order)
    local g=new("ScreenGui",{Name=name,ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=order,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local ok=pcall(function() g.Parent=parentGui end)
    if not ok or not g.Parent then g.Parent=LP:WaitForChild("PlayerGui") end
    return g
end
local gui,espGui,fpsGui=mkGui("luxxs",50),mkGui("luxxsESP",8),mkGui("luxxsFPS",100)

local toastHost=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.fromOffset(270,320),BackgroundTransparency=1,ZIndex=100,Parent=gui})
new("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,6),Parent=toastHost})
local function notify(text)
    local slot=new("Frame",{Size=UDim2.fromOffset(250,34),BackgroundTransparency=1,Parent=toastHost})
    local f=new("Frame",{Position=UDim2.fromOffset(280,0),Size=UDim2.fromScale(1,1),BackgroundColor3=C.panel,BorderSizePixel=0,Parent=slot}); stroke(f,C.line,1,0)
    local bar=new("Frame",{Size=UDim2.new(0,3,1,0),BorderSizePixel=0,Parent=f}); T(bar,"BackgroundColor3")
    new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(14,0),Font=F_MONO,TextSize=12,TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left,Text=text,Parent=f})
    tween(f,0.4,{Position=UDim2.fromOffset(0,0)})
    task.delay(2.6,function()
        if not f.Parent then return end
        tween(f,0.3,{Position=UDim2.fromOffset(280,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        task.delay(0.35,function() slot:Destroy() end)
    end)
end

local function makeDraggable(handle,target,onClick)
    local dragging,startPos,startInput,moved=false,nil,nil,false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; moved=false; startInput=input.Position; startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    dragging=false
                    if not moved and onClick then onClick() end
                end
            end)
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-startInput
            if delta.Magnitude>5 then moved=true end
            if moved then target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end
        end
    end))
end

-- one shared drag handler for every slider (cheaper than a connection per slider)
local dragFn,dragScroll=nil,nil
track(UIS.InputChanged:Connect(function(i)
    if dragFn and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then dragFn(i.Position.X) end
end))
track(UIS.InputEnded:Connect(function(i)
    if dragFn and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
        dragFn=nil
        if dragScroll then dragScroll.ScrollingEnabled=true; dragScroll=nil end
    end
end))

-- =====================================================================
-- KEY SCREEN
-- NOTE: the dark UIGradient lives on a plain Frame behind a transparent CanvasGroup.
-- A UIGradient on the CanvasGroup itself multiplies every child (this made the LUXXS letters black).
-- =====================================================================
local unlocked,afterKey=false,nil
do
    local sg=mkGui("luxxsKey",999)
    local bgF=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=1,Parent=sg})
    gradient(bgF,90,ColorSequence.new(Color3.fromRGB(20,26,22),Color3.fromRGB(7,9,8)))
    local root=new("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2,Parent=sg})

    local dots={}
    for i=1,28 do
        local f=new("Frame",{Size=UDim2.fromOffset(math.random(2,4),math.random(2,4)),BackgroundTransparency=0.55+math.random()*0.35,BorderSizePixel=0,Parent=root})
        T(f,"BackgroundColor3"); corner(f,2)
        dots[i]={f,math.random(),math.random(),0.01+math.random()*0.03}
    end
    task.spawn(function()
        while sg.Parent do
            local t=os.clock()
            for _,d in ipairs(dots) do
                d[1].Position=UDim2.fromScale((d[2]+t*d[4]*0.3)%1,(d[3]-t*d[4])%1)
            end
            task.wait(1/30)
        end
    end)
    for _,y in ipairs({0.1,0.9}) do
        local f=new("Frame",{Position=UDim2.fromScale(0,y),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundTransparency=0.85,Parent=root}); T(f,"BackgroundColor3")
    end
    new("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,18,0.1,8),Size=UDim2.fromOffset(240,16),Font=F_MONO,TextSize=11,TextColor3=C.dim,TextXAlignment=Enum.TextXAlignment.Left,Text="LUXXS // ACCESS",Parent=root})
    new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0.1,8),Size=UDim2.fromOffset(240,16),Font=F_MONO,TextSize=11,TextColor3=C.dim,TextXAlignment=Enum.TextXAlignment.Right,Text="DRHUB",Parent=root})
    new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,0.9,-8),Size=UDim2.fromOffset(300,16),Font=F_MONO,TextSize=10,TextColor3=C.dim,Text="v4.3  //  press ENTER to unlock",Parent=root})

    local word,LW="LUXXS",62
    local total=LW*#word
    local holder=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.36),Size=UDim2.fromOffset(total,84),BackgroundTransparency=1,ClipsDescendants=true,Parent=root})
    local letters={}
    for i=1,#word do
        letters[i]=new("TextLabel",{
            BackgroundTransparency=1,Size=UDim2.fromOffset(LW,84),Position=UDim2.fromOffset((i-1)*LW,98),
            Font=F_HEAD,TextSize=52,Text=word:sub(i,i),TextColor3=Color3.new(1,1,1),TextTransparency=0,
            TextStrokeTransparency=1,ZIndex=5,Parent=holder,
        })
    end
    local ul=new("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.36,52),Size=UDim2.fromOffset(0,2),BorderSizePixel=0,Parent=root}); T(ul,"BackgroundColor3")
    local sub=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.36,68),Size=UDim2.fromOffset(300,18),Font=F_MONO,TextSize=12,TextColor3=C.dim,Text="ENTER ACCESS KEY",TextTransparency=1,Parent=root})
    local kp=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.58),Size=UDim2.fromOffset(0,44),BackgroundColor3=C.row,BorderSizePixel=0,Visible=false,ClipsDescendants=true,Parent=root})
    local kst=stroke(kp,C.line,1,0)
    local ki=new("TextBox",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-112,1,0),Font=F_MONO,TextSize=14,TextColor3=C.text,PlaceholderText="KEY",PlaceholderColor3=C.dim,Text="",TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=kp})
    local kb=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),Size=UDim2.fromOffset(92,32),BorderSizePixel=0,Text="ENTER",Font=F_MONO,TextSize=13,TextColor3=C.bg,AutoButtonColor=false,Parent=kp}); T(kb,"BackgroundColor3")
    local kbar=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.fromOffset(0,2),BorderSizePixel=0,Parent=kp}); T(kbar,"BackgroundColor3")
    local st=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.58,36),Size=UDim2.fromOffset(340,18),Font=F_MONO,TextSize=12,TextColor3=C.dim,Text="",Parent=root})

    task.spawn(function()
        task.wait(0.2)
        for i,l in ipairs(letters) do
            tween(l,0.7,{Position=UDim2.fromOffset((i-1)*LW,0)})
            task.wait(0.09)
        end
        task.wait(0.3); tween(ul,0.6,{Size=UDim2.fromOffset(total,2)})
        task.wait(0.3); tween(sub,0.4,{TextTransparency=0})
        kp.Visible=true; tween(kp,0.5,{Size=UDim2.fromOffset(340,44)})
        pcall(function() ki:CaptureFocus() end)
    end)

    local function ripple(delay,size)
        task.delay(delay,function()
            local r=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.36),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,ZIndex=6,Parent=sg})
            corner(r,400)
            local s=stroke(r,ACC,3,0)
            tween(r,1.1,{Size=UDim2.fromOffset(size,size)})
            tween(s,1.1,{Transparency=1,Thickness=1})
            task.delay(1.2,function() r:Destroy() end)
        end)
    end
    local function burst()
        for i=1,36 do
            local a=math.rad(i/36*360+math.random(-6,6))
            local d=math.random(150,420)
            local f=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.36),BorderSizePixel=0,Size=UDim2.fromOffset(math.random(3,7),math.random(3,7)),BackgroundColor3=ACC,ZIndex=6,Parent=sg})
            corner(f,3)
            tween(f,math.random(70,120)/100,{Position=UDim2.new(0.5,math.cos(a)*d,0.36,math.sin(a)*d),BackgroundTransparency=1,Size=UDim2.fromOffset(1,1)})
            task.delay(1.3,function() f:Destroy() end)
        end
    end

    local done=false
    local function tryKey()
        if done then return end
        local txt=string.lower((ki.Text:gsub("^%s+",""):gsub("%s+$","")))
        if VALID_KEYS[txt] then
            done=true; ki.TextEditable=false
            st.Text="ACCESS GRANTED"; T(st,"TextColor3")
            tween(kbar,0.7,{Size=UDim2.new(1,0,0,2)},Enum.EasingStyle.Quart)
            task.wait(0.8)
            for i,l in ipairs(letters) do
                task.delay((i-1)*0.06,function()
                    tween(l,0.3,{TextColor3=ACC})
                    new("UIStroke",{Color=ACC,Thickness=1.5,Transparency=0.5,Parent=l})
                end)
            end
            ripple(0,1000); ripple(0.2,1500); burst()
            task.wait(1.1)
            for i,l in ipairs(letters) do
                task.delay((i-1)*0.05,function()
                    tween(l,0.4,{Position=UDim2.fromOffset((i-1)*LW,-110)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
                end)
            end
            tween(ul,0.4,{Size=UDim2.fromOffset(0,2)}); tween(kp,0.4,{Size=UDim2.fromOffset(0,44)})
            tween(root,0.7,{GroupTransparency=1}); tween(bgF,0.7,{BackgroundTransparency=1})
            task.wait(0.8); sg:Destroy(); unlocked=true
            if afterKey then afterKey() end
        else
            st.Text="INVALID KEY"; st.TextColor3=C.red; tween(kst,0.1,{Color=C.red})
            task.delay(0.6,function()
                if kp.Parent then tween(kst,0.3,{Color=C.line}); st.Text="" end
            end)
            local op=kp.Position
            for _,dx in ipairs({-10,10,-6,6,0}) do
                tween(kp,0.05,{Position=UDim2.new(op.X.Scale,op.X.Offset+dx,op.Y.Scale,op.Y.Offset)},Enum.EasingStyle.Linear)
                task.wait(0.055)
            end
        end
    end
    kb.MouseButton1Click:Connect(tryKey)
    ki.FocusLost:Connect(function(enter) if enter then tryKey() end end)
end

-- =====================================================================
-- WINDOW
-- =====================================================================
local W,H=930,460
local holder=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(W,H),BackgroundTransparency=1,Visible=false,Parent=gui})
local userScale=new("UIScale",{Parent=holder})
local animF=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Parent=holder})
local animScale=new("UIScale",{Scale=0.9,Parent=animF})
local main=new("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BorderSizePixel=0,GroupTransparency=1,Parent=animF}); BG(main,0)
local mainStroke=stroke(main,ACC,1.4,0.15); T(mainStroke,"Color")
local mainGrad=new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,WHITE),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(70,70,70)),ColorSequenceKeypoint.new(1,WHITE)}),Parent=mainStroke})
cornerTick(main,0,0,1,1,14,9); cornerTick(main,W,0,-1,1,14,9); cornerTick(main,0,H,1,-1,14,9); cornerTick(main,W,H,-1,-1,14,9)

local function fitScale()
    local cam=Workspace.CurrentCamera
    local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
    return math.clamp(math.min((vp.X-20)/W,(vp.Y-20)/H),0.3,1.2)*G.size
end
local function refit() userScale.Scale=fitScale() end
track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit))

local top=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.panel,BorderSizePixel=0,Parent=main}); BG(top,0)
new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0,Parent=top})
local mark=new("Frame",{Position=UDim2.fromOffset(16,18),Size=UDim2.fromOffset(8,8),Rotation=45,BorderSizePixel=0,Parent=top}); T(mark,"BackgroundColor3")
new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(34,0),Size=UDim2.fromOffset(90,44),Font=F_HEAD,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.text,Text="LUXXS",Parent=top})
new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(130,2),Size=UDim2.fromOffset(120,44),Font=F_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.dim,Text="by DrHub",Parent=top})
local crumb=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-52,0,0),Size=UDim2.fromOffset(300,44),Font=F_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,TextColor3=C.dim,Text="v4.3 // MM2",Parent=top})
local closeBtn=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(28,28),BackgroundColor3=C.row,BorderSizePixel=0,Text="X",Font=F_MONO,TextSize=13,TextColor3=C.dim,AutoButtonColor=false,Parent=top})

local side=new("Frame",{Position=UDim2.fromOffset(0,44),Size=UDim2.fromOffset(150,H-44-24),BackgroundColor3=C.panel,BorderSizePixel=0,Parent=main}); BG(side,0)
new("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.line,BorderSizePixel=0,Parent=side})
local sideList=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,10),Size=UDim2.new(1,-1,1,-50),Parent=side})
local indicator=new("Frame",{Size=UDim2.fromOffset(2,22),Position=UDim2.fromOffset(0,18),BorderSizePixel=0,ZIndex=3,Parent=side}); T(indicator,"BackgroundColor3")
local brand=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,16,1,-10),Size=UDim2.fromOffset(120,22),Font=F_HEAD,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,Text="luxxs",Parent=side}); T(brand,"TextColor3")
local brandS=new("UIStroke",{Thickness=1,Transparency=0.7,Parent=brand}); T(brandS,"Color")

local foot=new("Frame",{Position=UDim2.new(0,0,1,-24),Size=UDim2.new(1,0,0,24),BackgroundColor3=C.panel,BorderSizePixel=0,Parent=main}); BG(foot,0)
new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0,Parent=foot})
new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(166,0),Size=UDim2.fromOffset(380,24),Font=F_MONO,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.dim,Text="RIGHTSHIFT = TOGGLE   //   DRAG THE TOP BAR OR THE Lx ICON",Parent=foot})
local modLbl=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-190,0,0),Size=UDim2.fromOffset(140,24),Font=F_MONO,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,Text="ACTIVE 0",Parent=foot}); T(modLbl,"TextColor3")
local footR=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,0),Size=UDim2.fromOffset(160,24),Font=F_MONO,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,TextColor3=C.dim,Text="ROLE  INNOCENT",Parent=foot})

local pages=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(162,54),Size=UDim2.fromOffset(494,H-24-54-10),ClipsDescendants=true,Parent=main})
local previewPanel=new("Frame",{Position=UDim2.fromOffset(668,54),Size=UDim2.fromOffset(252,372),BorderSizePixel=0,Parent=main})

-- =====================================================================
-- TABS + CONTROL API (two-column flow, modules with gear, color picker)
-- =====================================================================
local tabs,currentTab,switching={},nil,false
local MAXH=335
local function restyleTabs()
    for _,t in ipairs(tabs) do
        local on=(t==currentTab)
        t.nm.TextColor3=on and C.text or C.dim
        t.num.TextColor3=on and ACC or C.dim
        t.button.BackgroundTransparency=on and 0.55 or 1
    end
end
local function selectTab(tab)
    if currentTab==tab or switching then return end
    switching=true
    local old=currentTab; currentTab=tab
    tween(indicator,0.3,{Position=UDim2.fromOffset(0,18+tab.index*34)})
    restyleTabs()
    if old then
        tween(old.page,0.15,{GroupTransparency=1})
        task.delay(0.15,function() old.page.Visible=false end)
    end
    task.delay(old and 0.12 or 0,function()
        tab.page.GroupTransparency=1; tab.page.Visible=true
        tween(tab.page,0.25,{GroupTransparency=0})
        task.delay(0.25,function() switching=false end)
    end)
end
local function hairline(parent,y)
    return new("Frame",{Position=UDim2.new(0,0,1,y or -1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0,Parent=parent})
end
local function rowLabel(r,txt,w)
    return new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,0),Size=UDim2.new(w or 1,w and 0 or -44,0,34),Font=F_BODY,TextSize=15,TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left,Text=txt,TextTruncate=Enum.TextTruncate.AtEnd,Parent=r})
end

local function makeApi(place,scroll)
    local api={}

    function api:Label(text)
        local f=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Parent=place(30)})
        new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,6),Size=UDim2.new(1,0,0,18),Font=F_SEC,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.dim,Text=string.upper(text),Parent=f})
        hairline(f,-3)
        local ac=new("Frame",{Position=UDim2.new(0,0,1,-3),Size=UDim2.fromOffset(28,1),BorderSizePixel=0,Parent=f}); T(ac,"BackgroundColor3")
    end

    function api:Custom(h)
        return new("Frame",{Size=UDim2.new(1,0,0,h),BackgroundTransparency=1,Parent=place(h)})
    end

    function api:Note(text,h)
        return new("TextLabel",{Size=UDim2.new(1,0,0,h or 18),BackgroundTransparency=1,Font=F_MONO,TextSize=10,TextColor3=C.dim,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text=text,Parent=place(h or 18)})
    end

    function api:Toggle(text,key,default,callback)
        local state=default or false
        local row=new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.row,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Text="",Parent=place(34)})
        hairline(row); rowLabel(row,text)
        local box=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(16,16),BackgroundColor3=C.bg,BorderSizePixel=0,Parent=row})
        local bs=stroke(box,C.off,1,0)
        local inner=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(state and 8 or 0,state and 8 or 0),BorderSizePixel=0,Parent=box}); T(inner,"BackgroundColor3")
        local function paint()
            bs.Color=state and ACC or C.off
            tween(inner,0.15,{Size=UDim2.fromOffset(state and 8 or 0,state and 8 or 0)})
        end
        themed[#themed+1]={bs,"Color",function(a) return state and a or C.off end}
        bs.Color=state and ACC or C.off
        register(key,state,function(v)
            state=v and true or false
            Flags[key]=state; paint()
            if callback then task.spawn(callback,state) end
        end)
        row.MouseButton1Click:Connect(function() Setters[key](not state); notify(text..(state and "  ON" or "  OFF")) end)
        row.MouseEnter:Connect(function() tween(row,0.12,{BackgroundTransparency=0.5}) end)
        row.MouseLeave:Connect(function() tween(row,0.12,{BackgroundTransparency=1}) end)
    end

    function api:Button(text,callback)
        local wrap=new("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,Parent=place(38)})
        local b=new("TextButton",{Position=UDim2.fromOffset(6,4),Size=UDim2.new(1,-12,0,30),BackgroundColor3=C.bg,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Font=F_MONO,TextSize=12,Text=string.upper(text),Parent=wrap})
        T(b,"TextColor3")
        local bs=stroke(b,ACC,1,0.4); T(bs,"Color")
        b.MouseEnter:Connect(function() b.BackgroundColor3=ACC; tween(b,0.12,{BackgroundTransparency=0}); b.TextColor3=C.bg end)
        b.MouseLeave:Connect(function() tween(b,0.12,{BackgroundTransparency=1}); b.TextColor3=ACC end)
        b.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
        return b
    end

    function api:Input(text,key,default,callback)
        local row=new("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,Parent=place(38)})
        hairline(row); rowLabel(row,text,0.4)
        local boxF=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),Size=UDim2.new(0.6,-8,0,26),BackgroundColor3=C.bg,BorderSizePixel=0,Parent=row})
        local bs=stroke(boxF,ACC,1,0.4); T(bs,"Color")
        local tb=new("TextBox",{BackgroundTransparency=1,Size=UDim2.new(1,-10,1,0),Position=UDim2.fromOffset(5,0),Font=F_MONO,TextSize=12,TextColor3=C.text,PlaceholderColor3=C.dim,PlaceholderText="value",Text=tostring(default or ""),ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Center,Parent=boxF})
        if key then
            register(key,tostring(default or ""),function(v)
                Flags[key]=tostring(v); tb.Text=Flags[key]
                if callback then task.spawn(callback,Flags[key],tb) end
            end)
        end
        tb.FocusLost:Connect(function()
            if key then Setters[key](tb.Text) elseif callback then task.spawn(callback,tb.Text,tb) end
        end)
        return tb
    end

    function api:Slider(text,key,min,max,default,callback,fmt,step)
        step=step or 1
        local value=default
        local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,Parent=place(44)})
        hairline(row)
        new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,3),Size=UDim2.new(0.6,0,0,20),Font=F_BODY,TextSize=15,TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left,Text=text,Parent=row})
        local val=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,3),Size=UDim2.fromOffset(90,20),Font=F_MONO,TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,Text="",Parent=row}); T(val,"TextColor3")
        local bar=new("Frame",{Position=UDim2.new(0,8,0,32),Size=UDim2.new(1,-16,0,2),BackgroundColor3=C.off,BorderSizePixel=0,Parent=row})
        local fill=new("Frame",{Size=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=bar}); T(fill,"BackgroundColor3")
        local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(6,14),BackgroundColor3=C.text,BorderSizePixel=0,ZIndex=3,Parent=bar})
        local function apply(v,silent)
            v=math.clamp(math.floor((tonumber(v) or min)/step+0.5)*step,min,max)
            value=v; Flags[key]=v
            val.Text=fmt and fmt(v) or tostring(v)
            local r=(v-min)/(max-min)
            if silent then
                fill.Size=UDim2.fromScale(r,1); knob.Position=UDim2.fromScale(r,0.5)
            else
                tween(fill,0.08,{Size=UDim2.fromScale(r,1)},Enum.EasingStyle.Linear)
                tween(knob,0.08,{Position=UDim2.fromScale(r,0.5)},Enum.EasingStyle.Linear)
            end
            if callback and not silent then task.spawn(callback,v) end
        end
        register(key,default,function(v) apply(v,false) end)
        apply(default,true)
        local hit=new("TextButton",{BackgroundTransparency=1,Text="",Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,24),Parent=row})
        local function update(x)
            Setters[key](min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1))
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                dragFn=update; dragScroll=scroll; scroll.ScrollingEnabled=false; update(i.Position.X)
            end
        end)
    end

    function api:Choice(text,key,options,default,callback)
        local idx=table.find(options,default) or 1
        local row=new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.row,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Text="",Parent=place(34)})
        hairline(row); rowLabel(row,text,0.45)
        local val=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,0),Size=UDim2.new(0.55,-8,1,0),Font=F_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Text="< "..options[idx].." >",Parent=row}); T(val,"TextColor3")
        register(key,options[idx],function(v)
            local i=table.find(options,v); if not i then return end
            idx=i; Flags[key]=options[i]; val.Text="< "..options[i].." >"
            if callback then task.spawn(callback,options[i]) end
        end)
        row.MouseButton1Click:Connect(function() Setters[key](options[idx%#options+1]) end)
        row.MouseButton2Click:Connect(function() Setters[key](options[(idx-2)%#options+1]) end)
        row.MouseEnter:Connect(function() tween(row,0.12,{BackgroundTransparency=0.5}) end)
        row.MouseLeave:Connect(function() tween(row,0.12,{BackgroundTransparency=1}) end)
    end

    -- color picker: palette + hue / saturation / brightness ("shade") + rainbow
    function api:Color(text,key,default,callback)
        local def=typeof(default)=="Color3" and hsvOf(default) or copyColor(default)
        local wrap=new("Frame",{Size=UDim2.new(1,0,0,34),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=place(34)})
        new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Parent=wrap})
        local head=new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.row,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Text="",LayoutOrder=1,Parent=wrap})
        hairline(head); rowLabel(head,text,0.55)
        local sw=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(44,16),BorderSizePixel=0,Parent=head}); corner(sw,3); stroke(sw,C.line,1,0)
        local panel=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false,LayoutOrder=2,Parent=wrap})
        new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=panel})
        new("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),Parent=panel})
        local grid=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1,Parent=panel})
        new("UIGridLayout",{CellSize=UDim2.fromOffset(22,22),CellPadding=UDim2.fromOffset(5,5),Parent=grid})
        local cur
        local sliders={}
        local function refreshAll()
            sw.BackgroundColor3=colorOf(cur,os.clock())
            for _,f in ipairs(sliders) do f() end
        end
        local function mini(label,get,set,order)
            local r=new("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=order,Parent=panel})
            new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(44,22),Font=F_MONO,TextSize=10,TextColor3=C.dim,TextXAlignment=Enum.TextXAlignment.Left,Text=label,Parent=r})
            local bar=new("Frame",{Position=UDim2.new(0,48,0.5,-1),Size=UDim2.new(1,-52,0,3),BackgroundColor3=C.off,BorderSizePixel=0,Parent=r})
            local fill=new("Frame",{Size=UDim2.fromScale(get(),1),BorderSizePixel=0,Parent=bar}); T(fill,"BackgroundColor3")
            local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(get(),0.5),Size=UDim2.fromOffset(6,12),BackgroundColor3=C.text,BorderSizePixel=0,ZIndex=3,Parent=bar})
            local hit=new("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),Parent=r})
            local function upd(x) set(math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)) end
            hit.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    dragFn=upd; dragScroll=scroll; scroll.ScrollingEnabled=false; upd(i.Position.X)
                end
            end)
            sliders[#sliders+1]=function()
                local v=get()
                fill.Size=UDim2.fromScale(v,1); knob.Position=UDim2.fromScale(v,0.5)
            end
        end
        local function commit()
            Flags[key]=copyColor(cur); refreshAll()
            if callback then task.spawn(callback,Flags[key]) end
        end
        register(key,def,function(v)
            if type(v)=="table" and v.h then cur=copyColor(v); commit() end
        end)
        cur=copyColor(def)
        local presets={
            Color3.fromRGB(86,255,126),Color3.fromRGB(196,255,61),Color3.fromRGB(0,220,255),Color3.fromRGB(110,214,255),
            Color3.fromRGB(70,110,255),Color3.fromRGB(158,110,255),Color3.fromRGB(255,110,200),Color3.fromRGB(255,60,60),
            Color3.fromRGB(255,150,40),Color3.fromRGB(255,214,10),Color3.fromRGB(255,255,255),Color3.fromRGB(150,150,160),
        }
        for _,pc in ipairs(presets) do
            local b=new("TextButton",{BackgroundColor3=pc,BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=grid}); corner(b,4)
            b.MouseButton1Click:Connect(function() cur=hsvOf(pc); commit() end)
        end
        mini("HUE",function() return cur.h end,function(v) cur.h=v; cur.rb=false; commit() end,2)
        mini("SAT",function() return cur.s end,function(v) cur.s=v; cur.rb=false; commit() end,3)
        mini("SHADE",function() return cur.v end,function(v) cur.v=v; commit() end,4)
        local rb=new("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="",LayoutOrder=5,Parent=panel})
        local rbL=new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=F_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Text="",Parent=rb})
        sliders[#sliders+1]=function()
            rbL.Text=(cur.rb and "[x] " or "[ ] ").."RAINBOW"
            rbL.TextColor3=cur.rb and ACC or C.dim
        end
        rb.MouseButton1Click:Connect(function() cur.rb=not cur.rb; commit() end)
        head.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)
        head.MouseEnter:Connect(function() tween(head,0.12,{BackgroundTransparency=0.5}) end)
        head.MouseLeave:Connect(function() tween(head,0.12,{BackgroundTransparency=1}) end)
        refreshAll()
        task.spawn(function()
            while wrap.Parent do
                if cur.rb then sw.BackgroundColor3=colorOf(cur,os.clock()) end
                task.wait(0.1)
            end
        end)
    end

    -- module row: checkbox + gear; the gear opens that module's settings
    function api:Module(text,key,default,callback,build)
        local state=default or false
        local wrap=new("Frame",{Size=UDim2.new(1,0,0,34),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=place(34)})
        new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Parent=wrap})
        local head=new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.row,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Text="",LayoutOrder=1,Parent=wrap})
        hairline(head)
        rowLabel(head,text,1).Size=UDim2.new(1,-76,0,34)
        local box=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(16,16),BackgroundColor3=C.bg,BorderSizePixel=0,Parent=head})
        local bs=stroke(box,C.off,1,0)
        local inner=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(state and 8 or 0,state and 8 or 0),BorderSizePixel=0,Parent=box}); T(inner,"BackgroundColor3")
        local function paint()
            bs.Color=state and ACC or C.off
            tween(inner,0.15,{Size=UDim2.fromOffset(state and 8 or 0,state and 8 or 0)})
        end
        themed[#themed+1]={bs,"Color",function(a) return state and a or C.off end}
        bs.Color=state and ACC or C.off
        register(key,state,function(v)
            state=v and true or false
            Flags[key]=state; paint()
            if callback then task.spawn(callback,state) end
        end)
        local gear=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-32,0.5,0),Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,Text="",ZIndex=3,Parent=head})
        local gi=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,Parent=gear})
        local ring=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(10,10),BackgroundTransparency=1,Parent=gi}); corner(ring,5)
        local rs=stroke(ring,C.dim,2,0)
        local teeth={}
        for a=0,3 do
            teeth[#teeth+1]=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(3,18),BackgroundColor3=C.dim,BorderSizePixel=0,Rotation=a*45,Parent=gi})
        end
        local settings=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.panel,BackgroundTransparency=0.3,BorderSizePixel=0,Visible=false,LayoutOrder=2,Parent=wrap})
        new("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=settings})
        new("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingBottom=UDim.new(0,6),PaddingTop=UDim.new(0,4),Parent=settings})
        local open=false
        gear.MouseButton1Click:Connect(function()
            open=not open; settings.Visible=open
            tween(gi,0.3,{Rotation=open and 90 or 0})
            for _,tt in ipairs(teeth) do tt.BackgroundColor3=open and ACC or C.dim end
            rs.Color=open and ACC or C.dim
        end)
        head.MouseButton1Click:Connect(function() Setters[key](not state); notify(text..(state and "  ON" or "  OFF")) end)
        head.MouseEnter:Connect(function() tween(head,0.12,{BackgroundTransparency=0.5}) end)
        head.MouseLeave:Connect(function() tween(head,0.12,{BackgroundTransparency=1}) end)
        if build then build(makeApi(function() return settings end,scroll)) end
    end
    return api
end

local function createTab(name)
    local index=#tabs
    local button=new("TextButton",{Size=UDim2.new(1,0,0,31),Position=UDim2.fromOffset(0,index*34+4),BackgroundColor3=C.row,BackgroundTransparency=1,BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=sideList})
    local num=new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(16,0),Size=UDim2.fromOffset(24,31),Font=F_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.dim,Text=string.format("%02d",index+1),Parent=button})
    local nm=new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(46,0),Size=UDim2.new(1,-50,1,0),Font=F_SEC,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.dim,Text=string.upper(name),Parent=button})
    local page=new("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,GroupTransparency=1,Parent=pages})
    local scroll=new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=page}); T(scroll,"ScrollBarImageColor3")
    new("UIPadding",{PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,10),Parent=scroll})
    local cols=new("Frame",{Size=UDim2.fromScale(1,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=scroll})
    new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10),Parent=cols})
    local function col()
        local f=new("Frame",{Size=UDim2.new(0.5,-5,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=cols})
        new("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=f})
        return f
    end
    local cl,cr=col(),col()
    local used,cur=0,1
    local function place(h)
        if cur==1 and used+h>MAXH then cur=2; used=0 end
        used+=h
        return cur==1 and cl or cr
    end
    local tab=makeApi(place,scroll)
    tab.button,tab.page,tab.index,tab.name,tab.num,tab.nm=button,page,index,name,num,nm
    tabs[#tabs+1]=tab
    button.MouseButton1Click:Connect(function() selectTab(tab) end)
    button.MouseEnter:Connect(function() if currentTab~=tab then tween(nm,0.15,{TextColor3=C.text}) end end)
    button.MouseLeave:Connect(function() if currentTab~=tab then tween(nm,0.15,{TextColor3=C.dim}) end end)
    return tab
end

-- =====================================================================
-- OPEN / CLOSE / ICON
-- =====================================================================
local isOpen,busy=false,false
local function openMenu()
    if busy or isOpen then return end
    busy=true; isOpen=true; holder.Visible=true; refit()
    animScale.Scale=0.9; main.GroupTransparency=1
    tween(animScale,0.4,{Scale=1},Enum.EasingStyle.Back)
    tween(main,0.3,{GroupTransparency=0})
    task.delay(0.4,function() busy=false end)
end
local function closeMenu()
    if busy or not isOpen then return end
    busy=true; isOpen=false
    tween(animScale,0.25,{Scale=0.92},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    tween(main,0.25,{GroupTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    task.delay(0.27,function() holder.Visible=false; busy=false end)
end
local function toggleMenu() if isOpen then closeMenu() else openMenu() end end
closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseEnter:Connect(function() tween(closeBtn,0.12,{BackgroundColor3=Color3.fromRGB(190,56,56)}); closeBtn.TextColor3=WHITE end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn,0.12,{BackgroundColor3=C.row}); closeBtn.TextColor3=C.dim end)

local icon=new("TextButton",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(52,200),Size=UDim2.fromOffset(0,0),BackgroundColor3=C.bg,BorderSizePixel=0,AutoButtonColor=false,Text="",Visible=false,ZIndex=5,Parent=gui}); corner(icon,40)
local iconStroke=stroke(icon,ACC,2.5,0); T(iconStroke,"Color")
local iconGrad=new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,WHITE),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(40,40,40)),ColorSequenceKeypoint.new(1,WHITE)}),Parent=iconStroke})
local iconGlow=new("UIStroke",{Thickness=7,Transparency=0.82,Parent=icon}); T(iconGlow,"Color")
local iconL=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,-7,0.5,0),Size=UDim2.fromOffset(16,20),Font=F_HEAD,TextSize=16,TextColor3=C.text,Text="L",ZIndex=6,Parent=icon})
local iconX=new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,8,0.5,0),Size=UDim2.fromOffset(16,20),Font=F_HEAD,TextSize=16,Text="x",ZIndex=6,Parent=icon}); T(iconX,"TextColor3")
icon.MouseEnter:Connect(function() tween(icon,0.2,{Size=UDim2.fromOffset(62,62)},Enum.EasingStyle.Back) end)
icon.MouseLeave:Connect(function() tween(icon,0.2,{Size=UDim2.fromOffset(54,54)}) end)
makeDraggable(icon,icon,toggleMenu)
makeDraggable(top,holder)
track(UIS.InputBegan:Connect(function(input,processed)
    if not processed and unlocked and input.KeyCode==Enum.KeyCode.RightShift then toggleMenu() end
end))
afterKey=function()
    local home=icon.Position
    icon.Position=UDim2.fromScale(0.5,0.5); icon.Visible=true
    tween(icon,0.5,{Size=UDim2.fromOffset(72,72)},Enum.EasingStyle.Back)
    task.wait(0.5)
    tween(icon,0.85,{Position=home,Size=UDim2.fromOffset(54,54)})
    task.wait(0.4)
    openMenu()
    notify("Key accepted // RightShift or Lx icon")
end

-- =====================================================================
-- FEATURES (each block is scoped so the main chunk stays under the local limit)
-- =====================================================================
local X={}
local plist=Players:GetPlayers()
track(Players.PlayerAdded:Connect(function() plist=Players:GetPlayers() end))
track(Players.PlayerRemoving:Connect(function() task.defer(function() plist=Players:GetPlayers() end) end))

local function scanName(name)
    local n=string.lower(name)
    if n:find("knife") then return "Murderer" end
    if n:find("revolver") or (n:find("gun") and not n:find("shotgun") and not n:find("stun")) then return "Sheriff" end
    return nil
end
local function toolRole(c)
    if not c then return nil end
    for _,o in ipairs(c:GetChildren()) do
        if o:IsA("Tool") then
            local r=scanName(o.Name)
            if r then return r end
        end
    end
    return nil
end
local function getRole(plr)
    if plr.Team then
        local tl=string.lower(plr.Team.Name)
        if tl=="murderer" then return "Murderer" elseif tl=="sheriff" then return "Sheriff" elseif tl=="innocent" then return "Innocent" end
    end
    for _,src in ipairs({plr,plr.Character}) do
        for _,attr in ipairs({"Role","MM2Role","role"}) do
            local v=src:GetAttribute(attr)
            if v~=nil then
                local rl=string.lower(tostring(v))
                if rl=="murderer" or rl=="murder" then return "Murderer" elseif rl=="sheriff" then return "Sheriff" elseif rl=="innocent" then return "Innocent" end
            end
        end
    end
    return toolRole(plr.Character) or toolRole(plr:FindFirstChildOfClass("Backpack")) or "Innocent"
end
local roleCache={}
local function getRoleCached(plr)
    local c=roleCache[plr]
    local now=os.clock()
    if c and now-c.t<0.25 then return c.r end
    local r=getRole(plr)
    roleCache[plr]={r=r,t=now}
    return r
end
track(Players.PlayerRemoving:Connect(function(p) roleCache[p]=nil end))
local function isAlive(plr)
    local c=plr.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    return (h and r and h.Health>0) and true or false,c,h,r
end

-- ===== ESP + CHAMS (chams run on their own path so they never depend on on-screen checks) =====
do
    local esp={}
    local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local UP_T,UP_B=Vector3.new(0,2.7,0),Vector3.new(0,-3.1,0)
    local CORN={}
    for xi,x in ipairs({-1.9,1.9}) do
        for yi,y in ipairs({-3.1,2.7}) do
            for zi,z in ipairs({-1.1,1.1}) do CORN[(xi-1)*4+(yi-1)*2+zi]=Vector3.new(x,y,z) end
        end
    end
    local EDGES={{1,2},{3,4},{5,6},{7,8},{1,3},{2,4},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8}}

    local function eLine()
        return new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,Visible=false,Parent=espGui})
    end
    local function eText(sz,ay)
        return new("TextLabel",{AnchorPoint=Vector2.new(0.5,ay),Size=UDim2.fromOffset(200,sz+2),BackgroundTransparency=1,Font=F_MONO,TextSize=sz,TextColor3=WHITE,TextStrokeTransparency=0.4,Visible=false,Parent=espGui})
    end
    local function mkEsp()
        local d={shown=false,body=false,e3={},sk={},cn={}}
        d.box=new("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false,Parent=espGui})
        d.bs=stroke(d.box,WHITE,1.5,0)
        for i=1,12 do d.e3[i]=eLine() end
        for i=1,8 do d.cn[i]=eLine() end
        for i=1,14 do d.sk[i]=eLine() end
        d.role,d.name,d.dist=eText(13,1),eText(12,1),eText(11,0)
        d.wep,d.hpt=eText(10,0),eText(10,0.5)
        d.hpBg=new("Frame",{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.4,BorderSizePixel=0,Visible=false,Parent=espGui})
        d.hp=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=d.hpBg})
        d.tr=eLine()
        d.look=eLine()
        d.head=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,Visible=false,Parent=espGui}); corner(d.head,8)
        d.arrow=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(20,6),BorderSizePixel=0,Visible=false,Parent=espGui}); corner(d.arrow,3)
        return d
    end
    local function hideBody(d)
        if not d.body then return end
        d.body=false
        d.box.Visible,d.role.Visible,d.name.Visible,d.dist.Visible,d.hpBg.Visible,d.tr.Visible=false,false,false,false,false,false
        d.wep.Visible,d.hpt.Visible,d.head.Visible,d.look.Visible=false,false,false,false
        for _,l in ipairs(d.e3) do l.Visible=false end
        for _,l in ipairs(d.cn) do l.Visible=false end
        for _,l in ipairs(d.sk) do l.Visible=false end
    end
    local function hideEsp(d)
        if not d.shown then return end
        d.shown=false
        d.body=true; hideBody(d)
        d.arrow.Visible=false
    end
    function X.killEsp(p)
        local d=esp[p]
        if not d then return end
        for _,v in pairs(d) do
            if typeof(v)=="Instance" then pcall(function() v:Destroy() end) end
        end
        for _,l in ipairs(d.e3) do l:Destroy() end
        for _,l in ipairs(d.cn) do l:Destroy() end
        for _,l in ipairs(d.sk) do l:Destroy() end
        esp[p]=nil
    end
    track(Players.PlayerRemoving:Connect(X.killEsp))
    function X.killAllEsp() for p in pairs(esp) do X.killEsp(p) end end

    local function bindChar(d,ch)
        if d.char==ch then
            if ch and (not d.hrp or not d.hum) then
                d.hrp,d.hum=ch:FindFirstChild("HumanoidRootPart"),ch:FindFirstChildOfClass("Humanoid")
            end
            return
        end
        d.char,d.hrp,d.hum,d.pairs=ch,nil,nil,nil
        if ch then
            d.hrp,d.hum=ch:FindFirstChild("HumanoidRootPart"),ch:FindFirstChildOfClass("Humanoid")
            local prs={}
            for _,pr in ipairs(ch:FindFirstChild("UpperTorso") and R15 or R6) do
                local a,b=ch:FindFirstChild(pr[1]),ch:FindFirstChild(pr[2])
                if a and b then prs[#prs+1]={a,b} end
            end
            d.pairs=prs
        end
    end

    local wasOn=false
    function X.espStep(cam,t)
        local any=Flags.box or Flags.name or Flags.dist or Flags.hp or Flags.skel or Flags.tracer or Flags.role
            or Flags.arrows or Flags.headDot or Flags.lookLine or Flags.weaponTxt or Flags.hpTxt
        local chOn=Flags.chams or Flags.glow
        if not any and not chOn and not wasOn then return end
        wasOn=(any or chOn) and true or false
        local vp,camPos=cam.ViewportSize,cam.CFrame.Position
        local ecolBase,chamC,glowC=colorOf(Flags.espCol,t),colorOf(Flags.chamCol,t),colorOf(Flags.glowCol,t)
        local pulse=Flags.chamPulse and (0.5+0.5*math.sin(t*3)) or 0
        for _,p in ipairs(plist) do
            if p~=LP then
                local ch=p.Character
                local d=esp[p]
                local alive=false
                if ch and (any or chOn) then
                    if not d then d=mkEsp(); esp[p]=d end
                    bindChar(d,ch)
                    alive=(d.hrp and d.hum and d.hum.Health>0 and (d.hrp.Position-camPos).Magnitude<=Flags.espDist) and true or false
                elseif d then
                    bindChar(d,nil)
                end
                local role=(alive and (Flags.colorByRole or Flags.role)) and getRoleCached(p) or "Innocent"
                local rcol=ROLE_COLORS[role] or WHITE
                local ecol=Flags.colorByRole and rcol or ecolBase
                if d then
                    -- chams / glow: one Highlight parented to the character (survives respawns, never tied to screen visibility)
                    local hl=d.hl
                    if alive and chOn then
                        if not hl or hl.Parent~=ch then
                            if hl then hl:Destroy() end
                            hl=new("Highlight",{Name="luxxsHL",Parent=ch}); d.hl=hl
                        end
                        hl.Adornee=ch; hl.Enabled=true
                        hl.DepthMode=Flags.chamWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                        hl.FillColor=Flags.colorByRole and rcol or chamC
                        hl.OutlineColor=Flags.colorByRole and rcol or glowC
                        hl.FillTransparency=Flags.chams and math.clamp(Flags.chamTrans/100+pulse*0.25,0,1) or 1
                        hl.OutlineTransparency=Flags.glow and (0.1+pulse*0.3) or (Flags.chams and 0.6 or 1)
                    elseif hl then
                        hl.Enabled=false
                    end

                    if alive and any then
                        local hrp,hum,pos=d.hrp,d.hum,d.hrp.Position
                        local fr=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                        local sp0=cam:WorldToViewportPoint(pos)
                        local onScr=sp0.Z>0 and sp0.X>0 and sp0.X<vp.X and sp0.Y>0 and sp0.Y<vp.Y
                        -- offscreen arrow
                        if Flags.arrows and not onScr then
                            local dir=Vector2.new(sp0.X-vp.X/2,sp0.Y-vp.Y/2)
                            if sp0.Z<0 then dir=-dir end
                            if dir.Magnitude<1 then dir=Vector2.new(0,1) end
                            dir=dir.Unit
                            local rad=math.min(vp.X,vp.Y)*0.4
                            d.arrow.Visible=true; d.arrow.BackgroundColor3=ecol
                            d.arrow.Position=UDim2.fromOffset(vp.X/2+dir.X*rad,vp.Y/2+dir.Y*rad)
                            d.arrow.Rotation=math.deg(math.atan2(dir.Y,dir.X))
                            d.shown=true
                        else
                            d.arrow.Visible=false
                        end
                        local top,bot=cam:WorldToViewportPoint(pos+UP_T),cam:WorldToViewportPoint(pos+UP_B)
                        if top.Z>0 and bot.Z>0 then
                            d.shown=true; d.body=true
                            local h=bot.Y-top.Y
                            local w=h*0.55
                            local mx=(top.X+bot.X)/2
                            local x0,x1,y0,y1=mx-w/2,mx+w/2,top.Y,bot.Y
                            local style,boxOn=Flags.boxStyle,Flags.box
                            -- 2D box / fill
                            if boxOn and style~="3D" then
                                d.box.Visible=true
                                d.box.Position=UDim2.fromOffset(x0,y0); d.box.Size=UDim2.fromOffset(w,h)
                                d.bs.Transparency=style=="2D" and 0 or 1; d.bs.Color=ecol
                                if Flags.boxFill then
                                    d.box.BackgroundColor3=ecol
                                    d.box.BackgroundTransparency=1-Flags.boxFillA/100*0.6
                                else
                                    d.box.BackgroundTransparency=1
                                end
                            else
                                d.box.Visible=false
                            end
                            -- corner box
                            if boxOn and style=="Corner" then
                                local L=math.min(w,h)*0.3
                                local sg={{x0,y0,x0+L,y0},{x0,y0,x0,y0+L},{x1,y0,x1-L,y0},{x1,y0,x1,y0+L},{x0,y1,x0+L,y1},{x0,y1,x0,y1-L},{x1,y1,x1-L,y1},{x1,y1,x1,y1-L}}
                                for i,s in ipairs(sg) do setLine(d.cn[i],s[1],s[2],s[3],s[4],1.6,ecol) end
                            else
                                for _,l in ipairs(d.cn) do l.Visible=false end
                            end
                            -- 3D box
                            local ok3=false
                            if boxOn and style=="3D" then
                                local _,yaw=hrp.CFrame:ToOrientation()
                                local base=CFrame.new(pos)*CFrame.Angles(0,yaw,0)
                                local pts,okp={},true
                                for i=1,8 do
                                    local v=cam:WorldToViewportPoint(base*CORN[i])
                                    if v.Z<=0 then okp=false; break end
                                    pts[i]=v
                                end
                                if okp then
                                    ok3=true
                                    for i,e in ipairs(EDGES) do
                                        local a,b=pts[e[1]],pts[e[2]]
                                        setLine(d.e3[i],a.X,a.Y,b.X,b.Y,1.5,ecol)
                                    end
                                end
                            end
                            if not ok3 then for _,l in ipairs(d.e3) do l.Visible=false end end
                            -- texts
                            if Flags.name then
                                d.name.Visible=true
                                d.name.Text=p.DisplayName~=p.Name and (p.DisplayName.." (@"..p.Name..")") or p.Name
                                d.name.TextColor3=ecol
                                d.name.Position=UDim2.fromOffset(mx,top.Y-(Flags.role and 18 or 3))
                            else d.name.Visible=false end
                            if Flags.role then
                                d.role.Visible=true; d.role.Text=string.upper(role); d.role.TextColor3=rcol
                                d.role.Position=UDim2.fromOffset(mx,top.Y-3)
                            else d.role.Visible=false end
                            if Flags.dist then
                                d.dist.Visible=true; d.dist.Text="["..math.floor((camPos-pos).Magnitude).."m]"
                                d.dist.Position=UDim2.fromOffset(mx,bot.Y+2)
                            else d.dist.Visible=false end
                            if Flags.weaponTxt then
                                local tool=ch:FindFirstChildOfClass("Tool")
                                d.wep.Visible=tool~=nil
                                if tool then
                                    d.wep.Text=tool.Name; d.wep.TextColor3=ecol
                                    d.wep.Position=UDim2.fromOffset(mx,bot.Y+(Flags.dist and 14 or 2))
                                end
                            else d.wep.Visible=false end
                            -- health bar / text
                            if Flags.hp then
                                d.hpBg.Visible=true
                                d.hpBg.Position=UDim2.fromOffset(x0-7,y0); d.hpBg.Size=UDim2.fromOffset(3,h)
                                d.hp.Size=UDim2.fromScale(1,fr); d.hp.BackgroundColor3=Color3.fromHSV(0.33*fr,0.9,1)
                            else d.hpBg.Visible=false end
                            if Flags.hpTxt then
                                d.hpt.Visible=true; d.hpt.Text=tostring(math.floor(hum.Health))
                                d.hpt.TextColor3=Color3.fromHSV(0.33*fr,0.9,1)
                                d.hpt.Position=UDim2.fromOffset(x0-(Flags.hp and 20 or 12),y0+h*0.5)
                            else d.hpt.Visible=false end
                            -- tracer
                            if Flags.tracer then
                                local oy=Flags.tracerOrigin=="Top" and 0 or (Flags.tracerOrigin=="Center" and vp.Y/2 or vp.Y)
                                setLine(d.tr,vp.X/2,oy,mx,bot.Y,1.2,ecol)
                            else d.tr.Visible=false end
                            -- head dot + look direction
                            local head=ch:FindFirstChild("Head")
                            if Flags.headDot and head then
                                local hs=cam:WorldToViewportPoint(head.Position)
                                if hs.Z>0 then
                                    local s=math.clamp(h*0.1,4,16)
                                    d.head.Visible=true; d.head.Size=UDim2.fromOffset(s,s)
                                    d.head.Position=UDim2.fromOffset(hs.X,hs.Y); d.head.BackgroundColor3=ecol
                                else d.head.Visible=false end
                            else d.head.Visible=false end
                            if Flags.lookLine and head then
                                local a=cam:WorldToViewportPoint(head.Position)
                                local b=cam:WorldToViewportPoint(head.Position+head.CFrame.LookVector*6)
                                if a.Z>0 and b.Z>0 then setLine(d.look,a.X,a.Y,b.X,b.Y,1.5,ecol) else d.look.Visible=false end
                            else d.look.Visible=false end
                            -- skeleton
                            if Flags.skel and d.pairs then
                                for i=1,14 do
                                    local pr,l=d.pairs[i],d.sk[i]
                                    if pr then
                                        local s1,s2=cam:WorldToViewportPoint(pr[1].Position),cam:WorldToViewportPoint(pr[2].Position)
                                        if s1.Z>0 and s2.Z>0 then setLine(l,s1.X,s1.Y,s2.X,s2.Y,1.5,ecol) else l.Visible=false end
                                    else l.Visible=false end
                                end
                            else
                                for _,l in ipairs(d.sk) do l.Visible=false end
                            end
                        else
                            hideBody(d)
                        end
                    else
                        hideEsp(d)
                    end
                end
            end
        end
    end
end

-- ===== GUN ESP (dropped sheriff gun through walls) + teleport =====
do
    local set,vis={}, {}
    local folder=new("Folder",{Name="luxxsGun",Parent=gui})
    local NAMES={GunDrop=true,["Gun Drop"]=true,DroppedGun=true,SheriffGun=true}
    local function partOf(o)
        if o:IsA("BasePart") and NAMES[o.Name] then return o end
        if o:IsA("Tool") and o.Parent==Workspace and scanName(o.Name)=="Sheriff" then
            return o:FindFirstChild("Handle") or o:FindFirstChildWhichIsA("BasePart")
        end
        return nil
    end
    local function valid(p)
        if not p or not p.Parent then return false end
        if NAMES[p.Name] then return p:IsDescendantOf(Workspace) end
        local tl=p.Parent
        return tl:IsA("Tool") and tl.Parent==Workspace
    end
    local function add(o) local p=partOf(o); if p then set[p]=true end end
    local function drop(p)
        local v=vis[p]
        if not v then return end
        pcall(function() v.hl:Destroy() end)
        pcall(function() v.bb:Destroy() end)
        vis[p]=nil
    end
    for _,o in ipairs(Workspace:GetDescendants()) do add(o) end
    track(Workspace.DescendantAdded:Connect(add))
    track(Workspace.DescendantRemoving:Connect(function(o) if set[o] then set[o]=nil; drop(o) end end))
    function X.teleportToGun()
        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local best,bd
        for p in pairs(set) do
            if valid(p) then
                local dd=(p.Position-hrp.Position).Magnitude
                if not bd or dd<bd then best,bd=p,dd end
            end
        end
        if not best then notify("Gun not found"); return end
        hrp.CFrame=CFrame.new(best.Position+Vector3.new(0,3,0)); hrp.AssemblyLinearVelocity=Vector3.zero
        notify("Teleported to gun")
    end
    function X.gunStep(cam,t)
        local on=Flags.gunEsp
        for p in pairs(set) do
            if not valid(p) then
                set[p]=nil; drop(p)
            elseif on then
                local v=vis[p]
                if not v then
                    local hl=new("Highlight",{DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillTransparency=0.35,OutlineTransparency=0,Adornee=p,Parent=folder})
                    local bb=new("BillboardGui",{AlwaysOnTop=true,Size=UDim2.fromOffset(120,34),StudsOffset=Vector3.new(0,2.5,0),Adornee=p,Parent=folder})
                    local l=new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=F_MONO,TextSize=13,TextStrokeTransparency=0.3,Text="GUN",Parent=bb})
                    v={hl=hl,bb=bb,lbl=l}; vis[p]=v
                end
                local col=colorOf(Flags.gunCol,t)
                v.hl.FillColor=col; v.hl.OutlineColor=col; v.lbl.TextColor3=col
                v.lbl.Text="GUN ["..(cam and math.floor((p.Position-cam.CFrame.Position).Magnitude) or 0).."m]"
            else
                drop(p)
            end
        end
    end
    function X.killGun()
        for p in pairs(vis) do drop(p) end
        pcall(function() folder:Destroy() end)
    end
end

-- ===== TARGETING / AIMBOT / SILENT AIM =====
do
    local CLOSEST={"Head","Chest","Stomach"}
    local function resolvePart(ch,n)
        if n=="Head" then return ch:FindFirstChild("Head")
        elseif n=="Chest" then return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
        elseif n=="Stomach" then return ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("Torso")
        elseif n=="Left Arm" then return ch:FindFirstChild("LeftUpperArm") or ch:FindFirstChild("Left Arm")
        elseif n=="Right Arm" then return ch:FindFirstChild("RightUpperArm") or ch:FindFirstChild("Right Arm")
        elseif n=="Left Leg" then return ch:FindFirstChild("LeftUpperLeg") or ch:FindFirstChild("Left Leg")
        elseif n=="Right Leg" then return ch:FindFirstChild("RightUpperLeg") or ch:FindFirstChild("Right Leg") end
        return ch:FindFirstChild("HumanoidRootPart")
    end
    local rayP=RaycastParams.new()
    rayP.FilterType=Enum.RaycastFilterType.Exclude
    rayP.IgnoreWater=true
    pcall(function() rayP.RespectCanCollide=true end)
    local function visible(origin,ch,pos)
        rayP.FilterDescendantsInstances={LP.Character}
        local r=Workspace:Raycast(origin,pos-origin,rayP)
        return r==nil or r.Instance:IsDescendantOf(ch)
    end
    -- returns player, part, aim position (with optional prediction); never targets through walls when wall=true
    local function pickTarget(cfg)
        local cam=Workspace.CurrentCamera
        if not cam then return nil end
        local vp=cam.ViewportSize
        local ctr=Vector2.new(vp.X/2,vp.Y/2)
        local origin=cam.CFrame.Position
        local myRole=cfg.smart and getRoleCached(LP) or nil
        local bp,bpart,bd=nil,nil,cfg.fov
        for _,plr in ipairs(plist) do
            if plr~=LP then
                local ok,ch=isAlive(plr)
                if ok and (not cfg.smart or myRole=="Murderer" or getRoleCached(plr)=="Murderer") then
                    for _,n in ipairs(cfg.part=="Closest" and CLOSEST or {cfg.part}) do
                        local part=resolvePart(ch,n)
                        if part then
                            local sp=cam:WorldToViewportPoint(part.Position)
                            if sp.Z>0 then
                                local dd=(Vector2.new(sp.X,sp.Y)-ctr).Magnitude
                                if dd<bd and (not cfg.wall or visible(origin,ch,part.Position)) then bp,bpart,bd=plr,part,dd end
                            end
                        end
                    end
                end
            end
        end
        if not bp then return nil end
        local pos=bpart.Position
        if cfg.predict and cfg.predict>0 then pos=pos+bpart.AssemblyLinearVelocity*(cfg.predict/100) end
        return bp,bpart,pos
    end
    X.pickTarget=pickTarget

    pcall(function() RunService:UnbindFromRenderStep("luxxsAim") end)
    RunService:BindToRenderStep("luxxsAim",Enum.RenderPriority.Camera.Value+1,function(dt)
        if not Flags.aim then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        if Flags.aimAct=="Hold RMB" and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local plr,part,pos=pickTarget({fov=Flags.aimFov,part=Flags.aimPart,wall=Flags.aimWall,smart=Flags.aimSmart,predict=Flags.aimPredict})
        if pos then
            local a=1
            if Flags.aimMode=="Smooth" then a=1-math.exp(-(1.5+26*(1-Flags.aimSmooth/100))*dt) end
            cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,pos),a)
        end
    end)

    -- silent aim: redirects the shot (Mouse.Hit / Mouse.Target / Raycast) without moving the camera.
    -- Needs an executor with hookmetamethod; otherwise "Flick" mode is used (camera snaps for 2 frames on click).
    local Silent={pos=nil,part=nil,allow=true,hooked=false}
    local function installHooks()
        if Silent.hooked then return true end
        if not (hookmetamethod and newcclosure and getnamecallmethod) then return false end
        local chk=checkcaller or function() return false end
        local ok=pcall(function()
            local oldIndex
            oldIndex=hookmetamethod(game,"__index",newcclosure(function(self,key)
                if Silent.pos and self==mouse and not chk() then
                    if key=="Hit" then return CFrame.new(Silent.pos) elseif key=="Target" then return Silent.part end
                end
                return oldIndex(self,key)
            end))
            local oldNC
            oldNC=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
                if Silent.pos and self==Workspace and not chk() and getnamecallmethod()=="Raycast" then
                    local origin,dir,params=...
                    if typeof(origin)=="Vector3" and typeof(dir)=="Vector3" then
                        local d=Silent.pos-origin
                        return oldNC(self,origin,d.Unit*math.max(dir.Magnitude,d.Magnitude),params)
                    end
                end
                return oldNC(self,...)
            end))
        end)
        Silent.hooked=ok
        return ok
    end
    X.installSilent=function()
        if not installHooks() then notify("hookmetamethod missing: using Flick mode") end
    end

    local mk=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,Visible=false,ZIndex=3,Parent=espGui}); corner(mk,9)
    local mkS=stroke(mk,ACC,1.5,0); T(mkS,"Color")
    local sfov=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundTransparency=1,Visible=false,Parent=espGui}); corner(sfov,500)
    local sfovS=stroke(sfov,Color3.fromRGB(255,214,10),1.2,0.4)
    function X.silentStep(cam,t)
        local on=Flags.silent
        sfov.Visible=(on and Flags.silentFov)==true
        if sfov.Visible then
            local r=Flags.silentRadius*2
            sfov.Size=UDim2.fromOffset(r,r); sfovS.Color=colorOf(Flags.silentCol,t)
        end
        if not on then Silent.pos=nil; Silent.part=nil; mk.Visible=false; return end
        local plr,part,pos=pickTarget({fov=Flags.silentRadius,part=Flags.silentPart,wall=Flags.silentWall,smart=Flags.silentSmart,predict=Flags.silentPredict})
        if pos and Silent.allow then
            Silent.pos,Silent.part=pos,part
            if Flags.silentMark then
                local sp=cam:WorldToViewportPoint(pos)
                mk.Visible=sp.Z>0; mk.Position=UDim2.fromOffset(sp.X,sp.Y)
            else mk.Visible=false end
        else
            Silent.pos,Silent.part=nil,nil; mk.Visible=false
        end
    end
    track(UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            Silent.allow=math.random(1,100)<=Flags.silentChance
            if Flags.silent and Silent.pos and (Flags.silentMethod=="Flick" or not Silent.hooked) then
                local cam=Workspace.CurrentCamera
                local old=cam.CFrame
                cam.CFrame=CFrame.lookAt(old.Position,Silent.pos)
                task.spawn(function()
                    RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
                    if cam.Parent then cam.CFrame=old end
                end)
            end
        end
    end))
end

-- ===== CHARACTER: fly / noclip / spin / speed / jump =====
do
    local fly={on=false,vel=Vector3.zero,up=false,dn=false}
    local function flyStop(hum)
        for _,k in ipairs({"lv","ao","att"}) do
            if fly[k] then pcall(function() fly[k]:Destroy() end); fly[k]=nil end
        end
        fly.vel=Vector3.zero
        if fly.on and hum and hum.Parent then
            hum.PlatformStand=false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        fly.on=false
    end
    local function flyStart(hrp,hum)
        flyStop(nil)
        fly.att=new("Attachment",{Name="LxFlyA",Parent=hrp})
        fly.lv=new("LinearVelocity",{Attachment0=fly.att,MaxForce=math.huge,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,VectorVelocity=Vector3.zero,RelativeTo=Enum.ActuatorRelativeTo.World,Parent=hrp})
        fly.ao=new("AlignOrientation",{Mode=Enum.OrientationAlignmentMode.OneAttachment,Attachment0=fly.att,MaxTorque=math.huge,Responsiveness=60,RigidityEnabled=false,CFrame=hrp.CFrame-hrp.CFrame.Position,Parent=hrp})
        hum.PlatformStand=true; fly.on=true
    end
    local function mkBtn(txt,y)
        local b=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-24,0.5,y),Size=UDim2.fromOffset(56,46),BackgroundColor3=C.bg,BackgroundTransparency=0.1,BorderSizePixel=0,Text=txt,Font=F_MONO,TextSize=14,TextColor3=C.text,AutoButtonColor=false,Visible=false,ZIndex=5,Parent=gui})
        local s=stroke(b,ACC,1.5,0); T(s,"Color")
        return b
    end
    local upB,dnB=mkBtn("UP",-30),mkBtn("DN",30)
    local function hold(b,key)
        b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then fly[key]=true end end)
        b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then fly[key]=false end end)
    end
    hold(upB,"up"); hold(dnB,"dn")

    local spin={}
    local function spinClear(hum)
        for _,k in ipairs({"av","att"}) do
            if spin[k] then pcall(function() spin[k]:Destroy() end); spin[k]=nil end
        end
        if hum and spin.was then hum.AutoRotate=true end
        spin.was=false
    end
    local lastSafe,speedWas,jumpWas,ncTouched=nil,false,false,{}

    function X.charStep(dt,t,ch,hrp,hum)
        if Flags.speedOn then hum.WalkSpeed=Flags.speed; speedWas=true elseif speedWas then hum.WalkSpeed=16; speedWas=false end
        if Flags.jumpOn then hum.UseJumpPower=true; hum.JumpPower=Flags.jump; jumpWas=true elseif jumpWas then hum.JumpPower=50; jumpWas=false end
        if not Flags.fly and hum.FloorMaterial~=Enum.Material.Air then lastSafe=hrp.CFrame end
        if (Flags.fly or Flags.noclip or X.farmActive) and lastSafe and hrp.Position.Y<Workspace.FallenPartsDestroyHeight+80 then
            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=lastSafe+Vector3.new(0,4,0)
        end
        local cam=Workspace.CurrentCamera
        if Flags.fly then
            if not fly.on or not fly.lv or fly.lv.Parent~=hrp then flyStart(hrp,hum) end
            local cf,d=cam.CFrame,Vector3.zero
            if not UIS:GetFocusedTextBox() then
                if UIS:IsKeyDown(Enum.KeyCode.W) then d+=cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d-=cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d+=cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d-=cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then d+=Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then d-=Vector3.yAxis end
            end
            local md=hum.MoveDirection
            if d.Magnitude==0 and md.Magnitude>0.05 then d+=md end
            if fly.up then d+=Vector3.yAxis end
            if fly.dn then d-=Vector3.yAxis end
            fly.vel=fly.vel:Lerp(d.Magnitude>0 and d.Unit*Flags.flySpeed or Vector3.zero,1-math.exp(-10*dt))
            fly.lv.VectorVelocity=fly.vel
            fly.ao.Enabled=not Flags.spin
            local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
            if look.Magnitude>0.01 then fly.ao.CFrame=CFrame.lookAt(Vector3.zero,look) end
            upB.Visible,dnB.Visible=UIS.TouchEnabled,UIS.TouchEnabled
        elseif fly.on or fly.lv then
            flyStop(hum); upB.Visible,dnB.Visible=false,false
        end
        -- spin: slider 1..1000 maps to roughly 0.5 .. 100 rad/s
        if Flags.spin then
            if not spin.av or spin.av.Parent~=hrp then
                spinClear(nil)
                spin.att=new("Attachment",{Name="LxSpinA",Parent=hrp})
                spin.av=new("AngularVelocity",{Attachment0=spin.att,MaxTorque=math.huge,RelativeTo=Enum.ActuatorRelativeTo.World,Parent=hrp})
            end
            hum.AutoRotate=false; spin.was=true
            spin.av.AngularVelocity=Vector3.new(0,(0.4+Flags.spinSpeed*0.1)*(Flags.spinReverse and -1 or 1),0)
        elseif spin.av then
            spinClear(hum)
        end
    end
    track(RunService.Stepped:Connect(function()
        local ch=LP.Character
        if (Flags.noclip or X.farmNoclip) and ch then
            for _,p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then ncTouched[p]=true; p.CanCollide=false end
            end
        elseif next(ncTouched) then
            for p in pairs(ncTouched) do
                if p.Parent and (p.Name=="HumanoidRootPart" or p.Name=="Torso" or p.Name=="UpperTorso" or p.Name=="LowerTorso" or p.Name=="Head") then p.CanCollide=true end
            end
            ncTouched={}
        end
    end))
    track(UIS.JumpRequest:Connect(function()
        if Flags.infJump then
            local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
    function X.charReset()
        local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        flyStop(hum); spinClear(hum)
        if hum then hum.WalkSpeed=16; hum.PlatformStand=false; hum.AutoRotate=true end
        upB.Visible,dnB.Visible=false,false
    end
end

-- ===== COSMETICS: wings / hat / trail =====
do
    local Cos={}
    local function destroyCos(n)
        if Cos[n] then
            for _,o in ipairs(Cos[n].objs) do pcall(function() o:Destroy() end) end
            Cos[n]=nil
        end
    end
    X.destroyCos=destroyCos
    local function triDesc(a,b,c,th)
        if (b-a):Cross(c-a).Magnitude<1e-3 then return nil end
        local ab,ac,bc=b-a,c-a,c-b
        local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
        if abd>acd and abd>bcd then c,a=a,c elseif acd>bcd and acd>abd then a,b=b,a end
        ab,ac,bc=b-a,c-a,c-b
        local right=ac:Cross(ab).Unit
        local up=bc:Cross(right).Unit
        local back=bc.Unit
        local height=math.max(0.05,math.abs(ab:Dot(up)))
        return {
            {Vector3.new(th,height,math.max(0.05,math.abs(ab:Dot(back)))),CFrame.fromMatrix((a+b)/2,right,up,back)},
            {Vector3.new(th,height,math.max(0.05,math.abs(ac:Dot(back)))),CFrame.fromMatrix((a+c)/2,-right,up,-back)},
        }
    end
    local function wpart(model,pivot,cls,size,cf,col,mat,list,mix)
        local p=Instance.new(cls)
        p.Size,p.Color,p.Material=size,col,mat
        p.CanCollide,p.CanQuery,p.CanTouch,p.Massless,p.CastShadow=false,false,false,true,false
        local w=Instance.new("Weld")
        w.Part0,w.Part1,w.C0=pivot,p,cf
        w.Parent=p; p.Parent=model
        if list then list[#list+1]={p,mix,col} end
        return p
    end
    local function mkPivot(model,torso,c0)
        local pv=Instance.new("Part")
        pv.Size=Vector3.new(0.2,0.2,0.2); pv.Transparency=1
        pv.CanCollide,pv.CanQuery,pv.CanTouch,pv.Massless=false,false,false,true
        local w=Instance.new("Weld")
        w.Part0,w.Part1,w.C0=torso,pv,c0
        w.Parent=pv; pv.Parent=model
        return pv,w
    end

    function X.buildWings()
        destroyCos("wings")
        local ch=LP.Character
        local torso=ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
        if not torso then return end
        local model=Instance.new("Model"); model.Name="luxxsWings"
        local sc=Flags.wingSize/100
        local demon=Flags.wingStyle=="Demon"
        local Wg={model=model,pivots={},parts={},demon=demon}
        for _,side in ipairs({-1,1}) do
            if not demon then
                local rows={
                    {n=7,a0=4,a1=78,lens={5.6,5.9,5.6,5.1,4.5,3.9,3.3},wid=0.62,mix=0.7,z=0},
                    {n=7,a0=14,a1=104,lens={4.2,4.4,4.1,3.7,3.2,2.8,2.4},wid=0.7,mix=0.45,z=0.045},
                    {n=6,a0=26,a1=116,lens={2.8,2.7,2.4,2.1,1.8,1.5},wid=0.78,mix=0.2,z=0.09},
                }
                for ri,row in ipairs(rows) do
                    local pv,w=mkPivot(model,torso,CFrame.new(side*0.35,0.5,0.5))
                    Wg.pivots[#Wg.pivots+1]={w=w,side=side,lag=(ri-1)*0.22}
                    for i=1,row.n do
                        local th=math.rad(row.a0+(row.a1-row.a0)*(i-1)/(row.n-1))
                        local d=Vector3.new(side*math.cos(th),math.sin(th),0)
                        local nrm=Vector3.new(-d.Y,d.X,0)
                        local len,wid=row.lens[i]*sc,row.wid*sc
                        local b=len*0.62
                        local z=Vector3.new(0,0,row.z)
                        wpart(model,pv,"Part",Vector3.new(b,wid,0.04),CFrame.fromMatrix(d*(b/2)+z,d,nrm),WHITE,Enum.Material.SmoothPlastic,Wg.parts,row.mix*0.5)
                        local tri=triDesc(d*b+nrm*(wid/2)+z,d*b-nrm*(wid/2)+z,d*len+z,0.04)
                        if tri then
                            for _,td in ipairs(tri) do wpart(model,pv,"WedgePart",td[1],td[2],WHITE,Enum.Material.Neon,Wg.parts,row.mix) end
                        end
                    end
                end
            else
                local pv,w=mkPivot(model,torso,CFrame.new(side*0.35,0.5,0.5))
                Wg.pivots[#Wg.pivots+1]={w=w,side=side,lag=0}
                local function P(x,y) return Vector3.new(side*x*sc,y*sc,0) end
                local E,Wr=P(1.5,1.9),P(3.3,3.0)
                local tips={P(4.6,5.8),P(6.4,4.4),P(6.8,2.1),P(5.5,0.1),P(3.4,-1.5)}
                local B,O=P(0.4,-1.8),P(0,0)
                local dark=Color3.fromRGB(34,5,10)
                local function bone(a,b,th)
                    wpart(model,pv,"Part",Vector3.new(th,th,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),dark,Enum.Material.SmoothPlastic,Wg.parts,0.5)
                end
                local function memb(a,b,c)
                    local tri=triDesc(a,b,c,0.05)
                    if tri then
                        for _,td in ipairs(tri) do wpart(model,pv,"WedgePart",td[1],td[2],dark,Enum.Material.SmoothPlastic,Wg.parts,0.28) end
                    end
                end
                bone(O,E,0.24); bone(E,Wr,0.2)
                for i,tp in ipairs(tips) do
                    bone(Wr,tp,0.14-i*0.008)
                    local cl=wpart(model,pv,"Part",Vector3.new(0.2,0.2,0.2),CFrame.new(tp),WHITE,Enum.Material.Neon,Wg.parts,1)
                    cl.Shape=Enum.PartType.Ball
                end
                for i=1,#tips-1 do memb(Wr,tips[i],tips[i+1]) end
                memb(Wr,tips[#tips],B); memb(O,Wr,B)
            end
        end
        model.Parent=ch
        Wg.objs={model}
        Cos.wings=Wg
    end

    -- hat styles: Cone (smooth straw-hat cone like the screenshot), Halo, Crown
    function X.buildHat()
        destroyCos("hat")
        local ch=LP.Character
        local head=ch and ch:FindFirstChild("Head")
        if not head then return end
        local model=Instance.new("Model"); model.Name="luxxsHat"
        local parts={}
        local sz=Flags.hatSize/100
        local tr=Flags.hatTrans/100
        local style=Flags.hatStyle
        local function add(size,cf,shape,mat)
            local p=Instance.new("Part")
            p.Size=size
            p.CanCollide,p.CanQuery,p.CanTouch,p.Massless,p.CastShadow=false,false,false,true,false
            p.Material=mat or Enum.Material.SmoothPlastic
            p.Transparency=tr
            if shape then p.Shape=shape end
            local w=Instance.new("Weld")
            w.Part0,w.Part1,w.C0=head,p,cf
            w.Parent=p; p.Parent=model
            parts[#parts+1]=p
        end
        if style=="Cone" then
            local N=34
            local R,Ht=2.35*sz,2.05*sz
            local th=Ht/N
            for i=1,N do
                local t=(i-1)/N
                local r=R*(1-t)^1.12+0.05
                add(Vector3.new(th+0.004,r*2,r*2),CFrame.new(0,0.5+(i-1)*th+th/2,0)*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
            end
        elseif style=="Halo" then
            for i=1,24 do
                local a=i/24*math.pi*2
                add(Vector3.new(0.14*sz,0.09,0.34*sz),CFrame.new(math.cos(a)*1.05*sz,1.3,math.sin(a)*1.05*sz)*CFrame.Angles(0,-a,0),nil,Enum.Material.Neon)
            end
        else
            for i=1,16 do
                local a=i/16*math.pi*2
                add(Vector3.new(0.34*sz,0.22,0.2*sz),CFrame.new(math.cos(a)*0.95*sz,0.75,math.sin(a)*0.95*sz)*CFrame.Angles(0,-a,0),nil,Enum.Material.Metal)
            end
            for i=1,8 do
                local a=i/8*math.pi*2
                add(Vector3.new(0.2*sz,i%2==0 and 0.7 or 0.5,0.2*sz),CFrame.new(math.cos(a)*0.95*sz,1.15,math.sin(a)*0.95*sz),nil,Enum.Material.Neon)
            end
        end
        model.Parent=ch
        Cos.hat={objs={model},model=model,parts=parts,style=style}
    end

    function X.buildTrail()
        destroyCos("trail")
        local ch=LP.Character
        local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local a0=new("Attachment",{Name="luxxsA0",Parent=hrp})
        local a1=new("Attachment",{Name="luxxsA1",Parent=hrp})
        local tr=new("Trail",{Attachment0=a0,Attachment1=a1,LightEmission=1,FaceCamera=true,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}),Parent=hrp})
        Cos.trail={objs={a0,a1,tr},a0=a0,a1=a1,trail=tr}
    end

    local acc=0
    function X.cosStep(dt,t,ch)
        local Wg=Cos.wings
        if Flags.wings and (not Wg or Wg.model.Parent~=ch) then X.buildWings(); Wg=Cos.wings
        elseif not Flags.wings and Wg then destroyCos("wings"); Wg=nil end
        if Wg then
            local sp=Flags.wingSpeed
            for _,pvt in ipairs(Wg.pivots) do
                pvt.w.C0=CFrame.new(pvt.side*0.35,0.5,0.5)*CFrame.Angles(0,-pvt.side*math.rad(24+math.sin(t*sp-pvt.lag*3)*16),0)
            end
        end
        local Ht=Cos.hat
        if Flags.hat and (not Ht or Ht.model.Parent~=ch) then X.buildHat(); Ht=Cos.hat
        elseif not Flags.hat and Ht then destroyCos("hat"); Ht=nil end
        local Tr=Cos.trail
        if Flags.trail and (not Tr or not Tr.trail.Parent) then X.buildTrail(); Tr=Cos.trail
        elseif not Flags.trail and Tr then destroyCos("trail"); Tr=nil end
        acc+=dt
        if acc>0.08 then
            acc=0
            if Wg then
                local tint=colorOf(Flags.wingCol,t)
                local base=Wg.demon and Color3.fromRGB(34,5,10) or WHITE
                for _,e in ipairs(Wg.parts) do
                    if e[1].Parent then e[1].Color=((Wg.demon or e[2]>=1) and e[3] or base):Lerp(tint,e[2]) end
                end
            end
            if Ht then
                local n=#Ht.parts
                for i,p in ipairs(Ht.parts) do
                    local c=colorOf(Flags.hatCol,t,i*(Ht.style=="Cone" and 0.01 or 0.05))
                    if Ht.style=="Cone" then c=c:Lerp(Color3.new(0,0,0),0.2*(i/n)) end
                    p.Color=c
                end
            end
        end
        if Tr and Tr.trail.Parent then
            local w=Flags.trailWidth*0.4
            Tr.a0.Position=Vector3.new(0,w/2,0); Tr.a1.Position=Vector3.new(0,-w/2,0)
            Tr.trail.Lifetime=math.max(0.1,Flags.trailLen/10)
            local c=Flags.trailCol
            if c.rb then
                local kp={}
                for k=0,6 do kp[#kp+1]=ColorSequenceKeypoint.new(k/6,colorOf(c,t,-k/6*0.8)) end
                Tr.trail.Color=ColorSequence.new(kp)
            else
                Tr.trail.Color=ColorSequence.new(colorOf(c,t))
            end
        end
    end
    function X.cosRespawn() destroyCos("wings"); destroyCos("hat"); destroyCos("trail") end
end
