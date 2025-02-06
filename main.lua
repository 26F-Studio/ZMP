require("Zenitha")
ZENITHA.setAppName('ZMP')
ZENITHA.setFirstScene('player')
ZENITHA.setVersionText("v1.0")
ZENITHA.globalEvent.drawCursor=NULL
ZENITHA.globalEvent.clickFX=NULL
do
    local GC,FONT=GC,FONT
    local waiting
    local playing={}
    local lastDropTime=-1
    local masterObj={volume=1,lowgain=1,highgain=1}
    local function reset()
        for i=1,#playing do
            playing[i].src:stop()
            playing[i].src:release()
        end
        TABLE.clear(playing)
        lastDropTime=love.timer.getTime()

        masterObj.volume=1
        masterObj.lowgain=1
        masterObj.highgain=1
        TABLE.clear(WIDGET.active)
        local w
        w=WIDGET.new{
            type='slider',axis={0,1},pos={.5,1},
            x=-300,y=-35,w=200,
            lineWidth=1.5,
            fontSize=15,
            labelDist=10,widthLimit=80,
            disp=function() return masterObj.volume end,
            code=function(v)
                masterObj.volume=v
                for i=1,#playing do
                    playing[i].volume=v
                    playing[i].src:setVolume(v)
                end
            end,
            valueShow=function() return "" end,
        } w:reset() table.insert(WIDGET.active,w)
        w=WIDGET.new{
            type='slider',axis={0,1},pos={.5,1},
            x=-40,y=-35,w=160,
            lineWidth=1.5,
            disp=function() return masterObj.lowgain end,
            code=function(v)
                masterObj.lowgain=v
                for _,obj in next,playing do
                    obj.lowgain=v
                    obj.src:setFilter{type='bandpass',lowgain=v,highgain=obj.highgain,volume=1}
                end
            end,
            valueShow=function() return "" end,
        } w:reset() table.insert(WIDGET.active,w)
        w=WIDGET.new{
            type='slider',axis={0,1},pos={.5,1},
            x=180,y=-35,w=160,
            lineWidth=1.5,
            disp=function() return masterObj.highgain end,
            code=function(v)
                masterObj.highgain=v
                for _,obj in next,playing do
                    obj.highgain=v
                    obj.src:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=v,volume=1}
                end
            end,
            valueShow=function() return "" end,
        } w:reset() table.insert(WIDGET.active,w)
    end
    SCN.add('player',{
        keyDown=function(key)
            if key=='escape' then
                if playing[1] then
                    reset()
                elseif not TASK.lock('quit',1) then
                    love.event.quit()
                else
                    MSG('info',"Press again to quit")
                end
            elseif key=='space' then
                if playing[1] then
                    local m=playing[1].src:isPlaying()
                    for i=1,#playing do
                        if m then
                            playing[i].src:pause()
                        else
                            playing[i].src:play()
                        end
                    end
                end
            elseif key=='left' then
                for i=1,#playing do
                    playing[i].src:seek(math.max(playing[i].src:tell()-5,0))
                end
            elseif key=='right' then
                for i=1,#playing do
                    playing[i].src:seek(playing[i].src:tell()+5)
                end
            end
            return true
        end,
        fileDrop=function(file)
            if love.timer.getTime()-lastDropTime>1 and not love.keyboard.isDown('lctrl','rctrl') then reset() end
            waiting=0
            local suc,res=pcall(love.audio.newSource,file,'stream')
            if suc then
                local obj={
                    name=file:getFilename(),
                    shortname=file:getFilename():match(".+[\\/](.+)%.%w+$"),
                    src=res,volume=1,highgain=1,lowgain=1,
                }
                print(obj.shortname)
                table.insert(playing,obj)
                local w
                w=WIDGET.new{
                    type='slider',axis={0,1},pos={.5,1},
                    x=-300,y=-35*(#playing+1),w=200,
                    lineWidth=1.5,
                    fontSize=15,
                    text=obj.shortname,
                    labelDist=10,widthLimit=80,
                    disp=function() return obj.volume end,
                    code=function(v) obj.volume=v res:setVolume(v) end,
                    valueShow=function() return "" end,
                } w:reset() table.insert(WIDGET.active,w)
                w=WIDGET.new{
                    type='slider',axis={0,1},pos={.5,1},
                    x=-40,y=-35*(#playing+1),w=160,
                    lineWidth=1.5,
                    fontSize=25,
                    text="L",
                    labelDist=5,
                    disp=function() return obj.lowgain end,
                    code=function(v) obj.lowgain=v res:setFilter{type='bandpass',lowgain=v,highgain=obj.highgain,volume=1} end,
                    valueShow=function() return "" end,
                } w:reset() table.insert(WIDGET.active,w)
                w=WIDGET.new{
                    type='slider',axis={0,1},pos={.5,1},
                    x=180,y=-35*(#playing+1),w=160,
                    lineWidth=1.5,
                    fontSize=25,
                    text="H",
                    labelDist=5,
                    disp=function() return obj.highgain end,
                    code=function(v) obj.highgain=v res:setFilter{type='bandpass',lowgain=obj.lowgain,highgain=v,volume=1} end,
                    valueShow=function() return "" end,
                } w:reset() table.insert(WIDGET.active,w)
            else
                local name=file:getFilename():reverse()
                MSG('error',"Cannot load file "..name:sub(1,(name:find("[/\\]") or #name+1)-1):reverse())
            end
        end,
        update=function(dt)
            if waiting then
                waiting=waiting+dt
                if waiting>1 then
                    waiting=false
                    for i=1,#playing do
                        playing[i].src:setLooping(true)
                        playing[i].src:stop()
                    end
                    for i=1,#playing do
                        playing[i].src:play()
                    end
                end
            end
        end,
        draw=function()
            GC.clear(COLOR.lD)
            if playing[1] then
                GC.setColor(COLOR.LD)
                for i=1,#playing do
                    FONT.set(15)
                    GC.print(playing[i].name,20,20*i)
                end
                GC.setColor(COLOR.lG)
                GC.rectangle('fill',0,5,800*playing[1].src:tell()/playing[1].src:getDuration(),8)
            else
                GC.setColor(COLOR.L)
                FONT.set(70)
                GC.mStr("MrZ's Multitrack Player",400,200)
                FONT.set(30)
                GC.mStr("play multiple sound files together!",400,320)
                GC.mStr("Drag & drop files here",400,435-20*math.abs(math.sin(love.timer.getTime()*5)))
                FONT.set(15)
                GC.mStr("esc=clear space=pause/play left/right=adjust time",400,540)
            end
        end
    })
end
