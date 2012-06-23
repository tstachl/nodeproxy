Handlebars.registerPartial 'CommentInfo', """
<div class="feedcommentinfo">
	<span class="feedcommentdate">{{formatDate createdDate}}</span>
	{{#if myLike}}
	  · <a href="/chatter/likes/{{myLike.id}}" data-toggle="like" data-type="DELETE" class="feedcommentlike">Unlike</a>
	{{else}}
	  · <a href="/chatter/comments/{{id}}/likes" data-toggle="like" data-type="POST" class="feedcommentlike">Like</a>
	{{/if}}
	{{#if likes.total}}
	  · {{likes.total}} person(s)
	{{/if}}
</div>
"""

Handlebars.registerPartial 'Comment', """
<li class="feedcomment">
	<div class="feedcommentphoto thumbnail">
		<img src="{{user.photo.smallPhotoUrl}}" />
	</div>
	<div class="feedcommentcontent">
		<div class="feedcommentbody">
			<span class="feedcommentauthor">{{user.name}}:</span>
			{{body.text}}
		</div>
	</div>
  {{> CommentInfo}}
</li>
"""

Handlebars.registerPartial 'Comments', """
<ul class="feedcomments">
{{#if comments.comments.length}}
  {{#each comments.comments}}
    {{> Comment}}
  {{/each}}
{{/if}}
</ul>
"""

Handlebars.registerPartial 'FeedInfo', """
<div class="feediteminfo">
	<span class="feeditemdate">{{formatDate createdDate}}</span> · 
  <a href="#" data-toggle="comment" data-id="{{id}}" class="feeditemcomment">Comment</a>
	{{#if myLike}}
	  · <a href="/chatter/likes/{{myLike.id}}" data-toggle="like" data-type="DELETE" class="feeditemlike">Unlike</a>
	{{else}}
	  · <a href="/chatter/feed-items/{{id}}/likes" data-toggle="like" data-type="POST" class="feeditemlike">Like</a>
	{{/if}}
	{{#if likes.total}}
	  · {{likes.total}} person(s)
	{{/if}}
</div>
"""

Handlebars.registerPartial 'FeedItem', """
<li class="feeditem">
	<div class="feeditemphoto thumbnail">
		<img src="{{photoUrl}}" />
	</div>
	<div class="feeditemcontent">
		<div class="feeditembody">
			<span class="feeditemauthor">{{actor.name}}:</span>
			{{body.text}}
		</div>
	</div>
	{{> FeedInfo}}
	{{> Comments}}
</li>
"""

FeedItemPageTemplate = Handlebars.compile """
<ul class="feed">
	<li class="feedpost">
		<div class="feedpostcontent">
			<textarea autocomplete="off" cols="40" maxlength="255"></textarea>
			<button class="a-button">Send</button>
		</div>
	</li>
  {{#each items}}
    {{> FeedItem}}
  {{/each}}
</ul>
<!--
<ul class="pager">
  {{#if previousPageUrl}}
  <li class="previous">
    <a href="#">&larr; Previous</a>
  </li>
  {{else}}
  <li class="previous disabled">
    &larr; Previous
  </li>
  {{/if}}
  {{#if nextPageUrl}}
  <li class="next">
    <a href="#">Next &rarr;</a>
  </li>
  {{else}}
  <li class="next disabled">
    Next &rarr;
  </li>
  {{/if}}
</ul>
-->
"""

class Chatter
  username: ''
  password: ''
  clientId: ''
  clientSecret: ''
  objectId: ''
  
  constructor: (options) ->
    @username = options.username if options.username?
    @password = options.password if options.password?
    @clientId = options.clientId if options.clientId?
    @clientSecret = options.clientSecret if options.clientSecret?
    @objectId = options.objectId if options.objectId?
    
    @_initSalesforce()
    
    me = @
    
    $('body').on 'click.like.data-api', '[data-toggle="like"]', (e) ->
      e.preventDefault()
      url = $(this).attr('href')
      method = $(this).data('type') or 'GET'
      force.ajax "/#{force.apiVersion}#{url}", ->
        me.load()
      , null, method
    
    $('body').on 'click.send.data-api', '.feedpostcontent button', (e) ->
      e.preventDefault()
      text = $(this).parents('.feedpostcontent').find('textarea').val()
      url = "/chatter/feeds/record/#{me.objectId}/feed-items"
      method = 'POST'
      force.ajax "/#{force.apiVersion}#{url}", ->
        me.load()
      , null, method, JSON.stringify
        body:
          messageSegments: [
            { type: 'Text', text: text }
          ]
    
    $('body').on 'click.comment.data-api', '[data-toggle="comment"]', (e) ->
      e.preventDefault()
      id = $(this).data('id')
      $(this).parents('.feeditem').find('.feedcomments').prepend("""
  			<li class="feedcommentpost">
  				<div class="feedcommentpostcontent">
  					<textarea autocomplete="off" cols="40" maxlength="255"></textarea>
  					<button class="a-button">Send</button>
  				</div>
  			</li>
      """).find('button').click (e) ->
        e.preventDefault()
        force.ajax "/#{force.apiVersion}/chatter/feed-items/#{id}/comments", ->
          me.load()
        , null, 'POST', JSON.stringify
          body:
            messageSegments: [
              { type: 'Text', text: $(this).parents('.feedcommentpost').find('textarea').val() }
            ]
  
  load: ->
    force.recordFeedItems @objectId, $.proxy(@build, @)
  
  build: (rsp) ->
    $('#chatter').html FeedItemPageTemplate(@postProcess(rsp))
  
  _initSalesforce: ->
    if typeof force == 'undefined'
      return unless @username and @password and @clientId and @clientSecret
      client = require('force')
      window.force = new client @clientId, @clientSecret, null, '/api'
      force.login @username, @password, $.proxy(@load, @)
    else
      @load()
  
  postProcess: (rsp) ->
    $.each rsp.items, (index, item, all) =>
      item = @postProcessItem item
    console.log rsp.items
    rsp
  
  postProcessItem: (item) ->
    $.each item.comments.comments, (index, comment, all) =>
      comment = @postProcessComment comment
    item.photoUrl = @salesforceUrl item.photoUrl
    if item.attachment?.downloadUrl?
      item.attachment.downloadUrl = @salesforceUrl item.attachment.downloadUrl
    item
  
  postProcessComment: (comment) ->
    comment.user.photo.smallPhotoUrl = @salesforceUrl comment.user.photo.smallPhotoUrl
    comment
    
  salesforceUrl: (url) ->
    url = force.instanceUrl + url unless ~url.indexOf 'http'
    url = url + if ~url.indexOf '?' then '&' else '?'
    url = url + 'oauth_token=' + force.sessionId unless ~url.indexOf 'oauth_token'
    url

module.exports = Chatter