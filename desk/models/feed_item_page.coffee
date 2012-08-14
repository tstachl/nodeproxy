Model = require 'lib/model'
FeedItem = require 'models/feed_item'

module.exports = class FeedItemPage extends Model
  @field 'currentPageUrl', type: String
  @field 'isModifiedUrl', type: String
  @field 'nextPageUrl', type: String
  @field 'previousPageUrl', type: String
  
  @has_many FeedItem, as: 'items'