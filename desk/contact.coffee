module.exports =
  data: []
  
  _create: ->
    @_setupLoading()
    @_setupElement()
    
    @showLoading()
    
    @_initSalesforce()
    @options.source = (request, response) =>
      response $.ui.autocomplete.filter(@data, request.term)
    
    $.ui.autocomplete.prototype._create.call @
  
  _initSalesforce: ->
    unless sforce.connection.sessionId
      return unless @options.username && @options.password
      sforce.connection.login @options.username, @options.password
    
    fields = []
    for key, value of @options.mapping
      fields.push value
    
    sforce.connection.query "Select Id, #{fields.join(',')} From Contact",
      onSuccess: @_onSuccess
      onFailure: @_onFailure
      source: @
  
  _onSuccess: (queryResult, self) ->
    if queryResult.size > 0
      self.data = queryResult.getArray('records').map (item) ->
        obj = 
          value: "#{item.FirstName} #{item.LastName}, #{item.Account.Name}"
          id: item.Id
        
        for key, value of self.options.mapping
          if ~value.indexOf '.'
            obj[key] = item[value.split('.')[0]][value.split('.')[1]] or 'None'
          else
            obj[key] = item[value] or 'None'
        
        obj
      self.hideLoading()
  
  _onFailure: (error, self) ->
    alert "An error has occurred: #{error}"
  
  _renderMenu: (ul, items) ->
    return $.ui.autocomplete.prototype._renderMenu.call @, ul, items unless @options.category
    current = ''
    for key, item of items
      unless item[@options.category] is current
        ul.append "<li class=\"ui-autocomplete-category\">#{item[@options.category]}</li>"
        current = item[@options.category]
      @_renderItem ul, item
  
  _setupElement: ->
    @originalElement = @element;
    @element = @originalElement.hide().clone().insertAfter @originalElement
    @element.attr
      id: ''
      name: ''
    .val ''
    
    # change the options.select function
    fn = @options.select
    @options.select = (event, ui) =>
      @originalElement.val ui.item.id if ui.item && ui.item.id
      if @options.mapping
        for key, value of @options.mapping
          $("#customer_#{key}").val ui.item[key]
            
      fn event, ui if typeof fn is 'function'
    
  _setupLoading: ->
    @_loading = $('<img src="https://d3jyn100am7dxp.cloudfront.net/images/ajax-loader-small.gif?1339221073">')
    @_loading.hide().insertAfter @element
  
  showLoading: ->
    @_loading.show()
    @element.hide()
  
  hideLoading: ->
    @_loading.hide()
    @element.show()