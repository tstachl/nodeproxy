Model = require 'lib/model'
CommentPage = require 'models/comment_page'



module.exports = class FeedItem extends Model
  @field 'createdDate', type: Date
  @field 'event', type: Boolean
  @field 'id', type: String
  @field 'isBookmarkedByCurrentUser', type: Boolean
  @field 'isDeleteRestricted', type: Boolean
  @field 'isLikedByCurrentUser', { type: Boolean, default: no }
  @field 'modifiedDate', type: Date
  @field 'photoUrl', type: String
  @field 'type', type: String
  @field 'url', type: String
  
  @has_one CommentPage, as: 'comments'
    