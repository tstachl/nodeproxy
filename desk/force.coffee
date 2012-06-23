class Client
  constructor: (@clientId, @clientSecret = '', @loginUrl = 'https://login.salesforce.com/', proxyUrl = 'https://nodeproxy.herokuapp.com/api') ->
    if not proxyUrl 
      if location.protocol is 'file:'
        # PhoneGap
        @proxyUrl = null
      else
        # Visualforce
        @proxyUrl = "#{location.protocol}//#{location.hostname}/services/proxy"
    else
      # outside of VF
      @proxyUrl = proxyUrl
      @authzHeader = 'Authorization'
  
  setUserAgent: (@userAgentString) ->
    @
  
  setRefreshToken: (@refreshToken) ->
    @
  
  login: (@username, @password, callback, error) ->
    url = "#{@loginUrl}/services/oauth2/token"
    $.ajax
      type: 'POST'
      url: if @proxyUrl then @proxyUrl else url
      cache: no
      processData: no
      data: "grant_type=password&client_id=#{@clientId}&client_secret=#{@clientSecret}&username=#{@username}&password=#{@password}"
      success: (oauthResponse, status, xhr) =>
        @setSessionToken oauthResponse.access_token, null, oauthResponse.instance_url
        callback(oauthResponse, status, xhr)
      error: error
      dataType: 'json'
      beforeSend: (xhr) =>
        xhr.setRequestHeader 'Proxy', url if @proxyUrl
  
  setSessionToken: (@sessionId, @apiVersion = 'v25.0', instanceUrl) ->
    if instanceUrl
      @instanceUrl = instanceUrl
    else
      elements = location.hostname.split '.'
      instance = if elements.length is 3 then elements[0] else elements[1]
      @instanceUrl = "https://#{instance}.salesforce.com"
  
  refreshAccessToken: (callback, error) ->
    if @username and @password
      return @login @username, @password, callback, error
    url = "#{@loginUrl}/services/oauth2/token"
    $.ajax
      type: 'POST'
      url: if @proxyUrl then @proxyUrl else url
      cache: no
      processData: no
      data: "grant_type=refresh_token&client_id=#{@clientId}&refresh_token=#{@refreshToken}"
      success: callback
      error: error
      dataType: 'json'
      beforeSend: (xhr) =>
        xhr.setRequestHeader 'Proxy', url if @proxyUrl
  
  ajax: (path, callback, error, method, payload, retry) ->
    url = "#{@instanceUrl}/services/data#{path}"
    $.ajax
      type: method or 'GET'
      async: @asyncAjax
      url: if @proxyUrl then @proxyUrl else url
      contentType: 'application/json'
      cache: no
      processData: no
      data: payload
      success: callback
      error: if not @refreshToken or retry then error else (jqXHR, textStatus, errorThrown) =>
        if jqXHT.status is 401
          @refreshAccessToken (oauthResponse) =>
            @setSessionToken oauthResponse.access_token, null, oauthResponse.instance_url
            @ajax path, callback, error, method, payload, true
          , error
        else
          error jqXHR, textStatus, errorThrown
      dataType: 'json'
      beforeSend: (xhr) =>
        xhr.setRequestHeader 'Proxy', url if @proxyUrl
        if url.indexOf 'chatter' isnt -1
          xhr.setRequestHeader @authzHeader, "Bearer #{@sessionId}"
        else
          xhr.setRequestHeader @authzHeader, "OAuth #{@sessionId}"
        xhr.setRequestHeader 'X-User-Agent', "salesforce-toolkit-rest-javascript/#{@apiVersion}"
        xhr.setRequestHeader 'User-Agent', @userAgentString if @userAgentString
  
  versions: (callback, error) ->
    @ajax '/', callback, error
  
  resources: (callback, error) ->
    @ajax "/#{@apiVersion}/", callback, error
  
  describeGlobal: (callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/", callback, error
  
  metadata: (object, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}", callback, error
  
  describe: (object, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}/describe/", callback, error
  
  create: (object, fields, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}/", callback, error, "POST", JSON.stringify(fields)
  
  retrieve: (object, id, fieldList, callback, error) ->
    if not arguments[4]
      error = callback
      callback = fieldList
      fieldList = null
    
    fields = if fieldList then "?fields=#{fieldList}" else ''
    @ajax "/#{@apiVersion}/sobjects/#{object}/#{id}#{fields}", callback, error
  
  upsert: (object, externalIdField, externalId, fields, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}/#{externalIdField}/#{externalId}?_HttpMethod=PATCH", callback, error, 'POST', JSON.stringify(fields)
  
  update: (object, id, fields, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}/#{id}?_HttpMethod=PATCH", callback, error, 'POST', JSON.stringify(fields)
  
  delete: (object, id, fields, callback, error) ->
    @ajax "/#{@apiVersion}/sobjects/#{object}/#{id}", callback, error, 'DELETE'
  
  query: (soql, callback, error) ->
    @ajax "/#{@apiVersion}/query?q=#{escape(soql)}", callback, error
  
  search: (sosl, callback, error) ->
    @ajax "/#{@apiVersion}/search?q=#{escape(sosl)}", callback, error
  
  record: (id = 'me', callback, error) ->
    @ajax "/#{@apiVersion}/chatter/feeds/record/#{id}", callback, error
  
  recordFeedItems: (id = 'me', callback, error) ->
    @ajax "/#{@apiVersion}/chatter/feeds/record/#{id}/feed-items", callback, error

module.exports = Client