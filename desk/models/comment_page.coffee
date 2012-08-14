Model = require 'lib/model'

module.exports = class CommentPage extends Model
  @field 'currentPageUrl', type: String
  @field 'nextPageUrl', type: String
  @field 'total', type: Number