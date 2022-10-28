require("Zenitha")
Zenitha.setAppName('ZMP')
Zenitha.setFirstScene('player')
Zenitha.setVersionText("v1.0")
Zenitha.setDrawCursor(NULL)
Zenitha.setClickFX(false)
do
    local waiting
    local playing={}
    local lastDropTime=-1
    local function reset()
        for i=1,#playing do
            playing[i].src:stop()
            playing[i].src:release()
        end
        TABLE.cut(playing)
        lastDropTime=love.timer.getTime()
    end
    SCN.add('player',{
        keyDown=function(key)
            if key=='escape' then
                if playing[1] then
                    reset()
                elseif not TASK.lock('quit',1) then
                    love.event.quit()
                else
                    MES.new('info',"Press again to quit")
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
        end,
        fileDropped=function(file)
            if love.timer.getTime()-lastDropTime>1 then reset() end
            waiting=0
            local suc,res=pcall(love.audio.newSource,file,'stream')
            if suc then
                table.insert(playing,{
                    name=file:getFilename(),
                    src=res,
                })
            else
                local name=file:getFilename():reverse()
                MES.new('error',"Cannot load file "..name:sub(1,(name:find("[/\\]") or #name+1)-1):reverse())
            end
        end,
        update=function(dt)
            if waiting then
                waiting=waiting+dt
                if waiting>1 then
                    waiting=false
                    for i=1,#playing do
                        playing[i].src:setLooping(true)
                        playing[i].src:play()
                    end
                end
            end
        end,
        draw=function()
            GC.clear(COLOR.lD)
            GC.setColor(COLOR.L)
            if playing[1] then
                for i=1,#playing do
                    FONT.set(15)
                    GC.print(playing[i].name,20,20*i)
                end
                GC.setColor(COLOR.lG)
                GC.rectangle('fill',0,5,800*playing[1].src:tell()/playing[1].src:getDuration(),8)
            else
                FONT.set(80)
                GC.mStr("MrZ's Music Player",400,200)
                FONT.set(35)
                GC.mStr("play multiple sound files together!",400,320)
                FONT.set(30)
                GC.mStr("Drag & drop files here",400,435-20*math.abs(math.sin(love.timer.getTime()*5)))
                FONT.set(15)
                GC.mStr("esc=clear space=pause/play left/right=adjust time",400,540)
            end
        end
    })
end
