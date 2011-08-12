class @Editor

    constructor: ( options ) ->
        @tabstop  = 8
        @linewrap = 80
        @id = 'canvas'
        this[k] = v for own k, v of options
        @font = @loadFont()
        @canvas = document.getElementById(@id)
        nullCursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto"
        $('#cursor').css( 'cursor', nullCursor )
        $('#' + @id).css( 'cursor', nullCursor )
        @width = @canvas.clientWidth
        @height = @canvas.clientHeight
        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height
        @cursor = new Cursor 8, 16, @
        @grid = []
        @palette = [
            [ 0, 0, 0 ],
            [ 170, 0, 0 ],
            [ 0, 170, 0 ],
            [ 170, 85, 0 ],
            [ 0, 0, 170 ],
            [ 170, 0, 170 ],
            [ 0, 170, 170 ],
            [ 170, 170, 170 ],
            [ 85, 85, 85 ],
            [ 255, 85, 85 ],
            [ 85, 255, 85 ],
            [ 255, 255, 85 ],
            [ 85, 85, 255 ],
            [ 255, 85, 255 ],
            [ 85, 255, 255 ],
            [ 255, 255, 255 ]
        ]
        @fg = 7
        @bg = 0
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        setInterval( () =>
            @draw()
        , 10 )
        $("body").bind "keydown", (e) =>
            key = 
              left: 37
              up: 38
              right: 39
              down: 40
              f1: 112
              f2: 113
              f3: 114
              f4: 115
              f5: 116
              f6: 117
              f7: 118
              f8: 119
              f9: 120
              f10: 121
              f11: 122
              f12: 123

            console.log "keydown: " + e.which
            mod = e.shiftKey || e.altKey || e.ctrlKey
            switch e.which
              when key.left
                if (!mod)
                    @cursor.moveLeft()
                else if e.ctrlKey || e.shiftKey
                    if @bg > 0 then @bg-- else @bg = 7
              when key.right
                if (!mod)
                    @cursor.moveRight()
                else if e.ctrlKey || e.shiftKey #for now, mac os x has command for ctrl-right
                    if @bg < 7 then @bg++ else @bg = 0
                    
              when key.down
                if (!mod)
                    if @cursor.y < (@height - @cursor.height) / @cursor.height
                      @cursor.y++
                      @cursor.draw()
                else if e.ctrlKey
                    if @fg > 0 then @fg-- else @fg = 15
              when key.up
                if (!mod)
                    if @cursor.y > 0
                      @cursor.y--
                      @cursor.draw()
                else if (e.ctrlKey)
                    if @fg < 15 then @fg++ else @fg = 0
              else

        $("body").bind "keypress", (e) =>            
            char = String.fromCharCode(e.which)
            console.log "keypress: " + e.which + "/" + char
            pattern = ///
                [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`~-]
            ///
            if char.match(pattern) && e.which <= 255 && !e.ctrlKey
                @putChar(char.charCodeAt( 0 ) & 255);                    

        $('#' + @id).mousemove ( e ) =>
            @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left )  / @cursor.width )
            @cursor.y = Math.floor( e.pageY / @cursor.height )
            @cursor.draw()

        @drawPalette('fg')
        @drawPalette('bg')
    putChar: (charCode) ->
        @grid[@cursor.y] = [] if !@grid[@cursor.y]
        @grid[@cursor.y][@cursor.x] = { char: charCode, attr: ( @bg << 4 ) | @fg }
        @cursor.moveRight()

    drawPalette: (type) ->
        if type == 'fg' then palette = @palette else palette = @palette[0..7]
        container = $('<div class=palette>');
        for p in palette
            block = $('<span>')
            block.css "background-color", @toRgbaString(p)
            container.append(block)
        $(@canvas.parentElement).append(container);

    loadUrl: ( url ) ->
        req = new XMLHttpRequest
        req.open 'GET', url, false
        req.overrideMimeType 'text/plain; charset=x-user-defined'
        req.send null
        content = if req.status is 200 or req.status is 0 then req.responseText else ''
        return content

    loadFont: ->
        data = @loadUrl '8x16.dat'
        chars = []
        for i in [ 0 .. 255 ]
            chr = []
            for j in [ 0 .. 15 ]
                chr.push data.charCodeAt( i * 16 + j ) & 255
            chars.push chr 
        return chars

    draw: ->
        @ctx.fillStyle = "#000000"
        @ctx.fillRect 0, 0, @canvas.width, @canvas.height
        for y in [0..@grid.length - 1]
            continue if !@grid[y]?
            for x in [0..@grid[y].length - 1]
                continue if !@grid[y][x]?
                px = x * @cursor.width
                py = y * @cursor.height

                @ctx.fillStyle = @toRgbaString( @palette[ ( @grid[y][x].attr & 240 ) >> 4 ] )
                @ctx.fillRect px, py, 8, 16

                @ctx.fillStyle = @toRgbaString( @palette[ @grid[y][x].attr & 15 ] )
                chr = @font[ @grid[y][x].char ]
                for i in [ 0 .. 15 ]
                    line = chr[ i ]
                    for j in [ 0 .. 7 ]
                        if line & ( 1 << 7 - j )
                            @ctx.fillRect px + j, py + i, 1, 1

        @ctx.fill()
        return true

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)';

    class Cursor

        constructor: (@width, @height, @editor) ->
            @x = 0
            @y = 0
            @dom = $("#cursor")
            @dom.width @width
            @dom.height @height
            @draw()
        draw: ->
            @dom.css( 'top', @y * @height )
            @dom.css( 'left', @x * @width )
        moveRight: ->
            if @x < @editor.width/@width - 1
                @x++
            else if @y < @editor.height/@height - 1
                @x =0;
                @y++
            @draw()
            return true                
        moveLeft: ->
            if @x > 0
                @x--
            else if @y > 0
                @y--
                @x = @editor.width/@width - 1
            @draw()
            return true

$(document).ready ->
    $('#close').click ->
        $('#splash').hide()
        return false

    new Editor

