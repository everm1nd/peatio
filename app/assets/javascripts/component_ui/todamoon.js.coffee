@ToDaMoonUI = flight.component ->
  @attributes
    'send': '.btn-send'
    'box': '#chat-textarea'
    'chatroom': '.chat-body'
    'switcher': '#btn-todamoon'
    'nickname-form' : '#set-nickname-form'
    'limit-user-btn' : '#limit-user-btn'
    'chat-bottom' : '.chat-bottom'
    'online-peers' : '#online-peers'
    'open' : '.btn-open'
    'close' : '.btn-close'

  @after 'initialize', ->
    # at          通知消息时间戳
    # uid         用户唯一标识
    # nickname    用户昵称
    # limit_at    禁言到达时间戳
    # body        消息内容
    # sec         秒数

    # 支持命令事件
    # todamoon:cmd:send(body) 发送消息
    # todamoon:cmd:set_excessively_send(uid, sec) 禁言某用户

    @on @select('send'), 'click', =>
      content = @select('box').val()
      return if content.replace(/\s+/g, '') == ''
      if content.length > 200
        html = "<div class='alert alert-danger'><p>太长啦，我们是聊天室不是报社</p></div>"
        @select('chat-bottom').prepend(html).find('.alert').delay(2500).fadeOut()
      else 
        @trigger document, 'todamoon:cmd:send', body: content
        @select('box').val('')

    # 当前用户加入聊天室
    @on document, 'todamoon:notify:join', (e, d) ->
      html = ''
      if d['history'].length
        html += JST["templates/todamoon/receive"](h) for h in d['history']
      html += JST["templates/todamoon/join"]()
      @append_item(html)

    # 当前用户重复加入聊天室（连接已经断开）
    @on document, 'todamoon:notify:rejoin', ->
      html = JST["templates/todamoon/join"]({'type':'rejoin'})
      @append_item(html)

    # 某用户进入聊天室
    # uid, at, nickname
    @on document, 'todamoon:user:enter', (e, d) ->
      html = JST["templates/todamoon/user_enter"](d)
      @append_item(html)

    # 某用户离开聊天室
    # uid, at, nickname
    @on document, 'todamoon:user:leave', (e, d) ->
      html = JST["templates/todamoon/user_leave"](d)
      @append_item(html)

    # 某用户在聊天室中发言
    # body, at, nickname
    @on document, 'todamoon:user:send', (e, d) ->
      d['is_me'] = d['uid'] == gon.current_user['id']
      html = JST["templates/todamoon/receive"](d)
      @append_item(html)

    # 某用户被管理员限制发言
    # limit_at, uid, at, nickname
    @on document, 'todamoon:user:limit_send', (e, d) ->
      d['type'] = 'limit_send'
      html = JST["templates/todamoon/announcement"](d)
      @append_item(html)

    # 当前用户发言过快（未到达发言时限，默认间隔1秒）
    # limit_at
    @on document, 'todamoon:error:excessively_send', (e, d) ->
      d['type'] = 'excessively_send'
      html = JST["templates/todamoon/announcement"](d)
      @append_item(html)

    # 当前用户被管理员禁言
    # limit_at 禁言解除时间戳
    @on document, 'todamoon:error:limit_send', (e, d) ->
      d['type'] = 'forbidden_send'
      html = JST["templates/todamoon/announcement"](d)
      @append_item(html)

    # 某用户设置昵称
    # uid 用户标识
    # old_nickname 设置前昵称
    # nickname 设置后昵称
    @on document, 'todamoon:user:set', (e, d) ->
      d['type'] = 'nickname_changed'
      html = JST["templates/todamoon/announcement"](d)
      @append_item(html)

    # 获取房间信息
    # room_size 房间人数
    @on document, 'todamoon:room:info', (e, d) ->
      @select('online-peers').fadeOut().text(d.room_size+'人').fadeIn()

    @on @select('switcher'), 'click', =>
      if @$node.hasClass('expanded')
        @$node.removeClass('expanded')
      else
        @$node.addClass('expanded')

    @on @select('open'), 'click', (e) ->
      $($(e.currentTarget).data('target')).fadeToggle()

    @on @select('close'), 'click', (e) ->
      $($(e.currentTarget).data('target')).fadeToggle()

    @on @select('nickname-form'), 'ajax:success', (e, d) ->
      @trigger document, 'todamoon:cmd:set', d
      @select('nickname-form').fadeToggle()

    @on @select('nickname-form'), 'ajax:error', (e, d) ->
      html = "<div class='alert alert-danger'><p>#{d.responseText}, 请重试</p></div>"
      @select('chat-bottom').prepend(html).find('.alert').delay(2500).fadeOut()

    @on @select('limit-user-btn'), 'click', (e) ->
      uid = @$node.find('#limit-uid').val()
      limit_time = @$node.find('#limit-time').val()
      console.log uid, limit_time
      if uid && limit_time && $.isNumeric(limit_time)
        @trigger document, 'todamoon:cmd:set_excessively_send', {'uid': parseInt(uid), 'sec': parseInt(limit_time)}
        $('#limit-user-form').fadeToggle()
      else
        html = "<div class='alert alert-danger'><p>值不能为空，时间只能填数字</p></div>"
        @select('chat-bottom').prepend(html).find('.alert').delay(2500).fadeOut()


  @append_item = (html) ->
    chatroom = @select('chatroom')
    chatroom.append(html)
    posY = chatroom[0].scrollHeight - chatroom.height() - 16 
    if posY - chatroom.scrollTop() > 0
      chatroom.getNiceScroll().doScrollPos(0, posY, 200)
      chatroom.getNiceScroll().doScrollPos(0, posY, 200) #temporary fixing the scroll bug
