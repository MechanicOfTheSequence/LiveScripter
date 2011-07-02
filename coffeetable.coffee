###
CoffeeTable

A drop-in workbench for experimentation.
http://github.com/alecperkins/coffeetable
###

default_settings =
    coffeescript_js : "https://raw.github.com/alecperkins/coffeetable/master/lib/coffee_script-1.1.1-min.js"
    style:
      position        : 'fixed'
      top             : '5px'
      right           : '5px'
    local_storage   : true
    ls_key          : 'coffee-table'


log = -> console.log arguments
dir = -> console.dir arguments

class CoffeeTable
    settings = null
    $els = null

    styles = null
    result_styles = null
    template = ''

    active = false

    history_index = 0

    history =
        source: []
        result: []

    constructor: (opts) ->

        settings = default_settings
        for k, v of opts
            settings[k] = v

        styles =
            widget:
                'position'          : "#{ settings.style.position }"
                'top'               : "#{ settings.style.top }"
                'right'             : "#{ settings.style.right }"
                'background'        : 'rgba(255,255,255,0.9)'
                'padding'           : '0'
                'border'            : '2px solid white'
                'z-index'           : '9999999'
                'box-shadow'        : '0px 0px 4px #222'
                'font-size'         : '12px'
            button:
                'float'             : 'right'
                'background'        : 'white'
                'border'            : '1px solid #ccc'
                'color'             : '#991111'
            button_active:  
                'background'        : '#991111'
                'color'             : 'white'
            textarea:   
                'font-family'       : 'monospace'
                'font-size'         : '1em'
                'min-width'         : '400px'
                'min-height'        : '2em'
                'margin'            : '4px'
            div:
                'display'           : 'none'
            ul:
                'margin'            : '4px'
                'padding'           : '4px 4px 4px 16px'
                'font-family'       : 'monospace'
            li:
                'padding'           : '4px 4px 4px 0'
                'cursor'            : 'pointer'
            span:
                'padding'           : '4px'
                'text-align'        : 'center'
                'cursor'            : 'pointer'
                'float'             : 'right'
                'color'             : '#ccc'
                'font-variant'      : 'small-caps'
                'display'           : 'none'


        result_styles =
            'function' :
                'color'           : '#229922'
            'number':
                'color'           : '#222299'
            'string':
                'color'           : '#992222'
            'undefined':
                'color'           : 'grey'
                'font-style'      : 'italic'
            'object': {}
            'boolean':
                'color'           : '#229999'

        template = '<div><button>CoffeeTable</button><div><textarea></textarea><ul></ul><span>clear</span></div></div>'

        loadCSJS()
        renderWidget()

        if settings.local_storage
            loadFromStorage()

    loadFromStorage = ->
        previous_data = localStorage?.getItem('coffee-table')
        if previous_data?
            previous_data = JSON.parse(previous_data)
            
            # sloppy way to wait for coffeescript.js
            execHistory = ->
                if CoffeeScript?
                    execute(item) for item in previous_data
                else
                    setTimeout ->
                        execHistory()
                    , 500
            execHistory()

    execute = (source) ->
        history_index = -1
        history.source.push(source)

        error_output = null
        cs_error = false
        js_error = false

        try
            js = CoffeeScript.compile(source, { bare: on })
        catch error
            cs_error = true
            error_output = error
        
        if not error_output?
            try
                result = eval(js)
            catch eval_error
                js_error = true
                error_output = eval_error

        if error_output?
            result = error_output

        history.result.push(result)
        this_result_index = history.source.length - 1

        new_li = $("<li>#{ this_result_index }: <span>#{ result }</span></li>")
        new_li.css(styles.li)
        new_li.find('span').css(result_styles[typeof result])

        if cs_error
            new_li.css('color','orange')
        else if js_error
            new_li.css('color','red')
        
        new_li.hover ->
            new_li.css
                background          : 'rgba(255,255,0,0.2)'
                'list-style-type'   : 'disc'
        , ->
            new_li.css
                'background'        : ''
                'list-style-type'   : ''
        
        new_li.click ->
            loadPrevious(false, this_result_index)

        new_li.prependTo($els.ul)
        $els.span.show()
        localStorage?.setItem(settings.ls_key, JSON.stringify(history.source))


    clearHistory = ->
        $els.ul.empty()
        history.source = []
        history.result = []
        localStorage?.removeItem(settings.ls_key)
        $els.span.hide()

    loadPrevious = (forward=false, target_index) ->
        if target_index?
            history_index = target_index + 1 

        if history_index is -1
            history_index = history.source.length-1
        else
            if forward
                history_index += 1
            else
                history_index -= 1
        if history.source.length > 1
            $els.textarea.val(history.source[history_index])
            $els.textarea.selectionStart = 0
            $els.textarea.selectionEnd = 0

    renderWidget = ->
        widget = $(template)

        $els =
            widget      : widget
            textarea    : widget.find('textarea')
            ul          : widget.find('ul')
            button      : widget.find('button')
            div         : widget.find('div')
            span        : widget.find('span')
        for el_name, el of $els
            el.css(styles[el_name]) 

        $els.button.click ->
            if active
                $els.button.css(styles.button)
                $els.div.hide()
            else
                $els.button.css(styles.button_active)
                $els.div.show()
                $els.textarea.focus()
            active = not active

        $els.span.click ->
            clearHistory()
        $els.span.hover ->
            $els.span.css('color', '#991111')
        , ->
            $els.span.css('color', styles.span.color)

        $els.textarea.bind 'keydown', (e) ->
            entered_source = $els.textarea.val()
            if @selectionStart is 0
                if e.which is 38
                    console.log history_index
                    loadPrevious()
                else if e.which is 40
                    loadPrevious(true)
            if e.which is 13 and e.shiftKey
                e.preventDefault()
                if entered_source isnt ''
                    execute(entered_source)
                    $els.textarea.val('')
            else if e.which is 9
                e.preventDefault()
                start = @selectionStart
                end = @selectionEnd
                @value = @value.substring(0,start) + "    " + @value.substring(start)
                @selectionStart = start + 4
                @selectionEnd = start + 4


        widget.appendTo('body')

    loadCSJS = ->
        if not window.CoffeeScript?
            script_el = document.createElement('script')
            script_el.type ='application/javascript'
            script_el.src = default_settings.coffeescript_js
            $('head').append(script_el)
    
    show: ->
        $els.widget.show()
        return this
    
    hide: ->
        $els.widget.hide()
        return this

window.CoffeeTable = CoffeeTable

$(document).ready ->
    window.coffeetable = new CoffeeTable()