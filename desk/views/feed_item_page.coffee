module.exports = Handlebars.compile """
<ul class="feed">
  {{get this "currentPageUrl"}}
</ul>
<ul class="pager">
  {{#if this.previousPageUrl}}
  <li class="previous">
    <a href="#">&larr; Previous</a>
  </li>
  {{else}}
  <li class="previous disabled">
    &larr; Previous
  </li>
  {{/if}}
  {{#if this.nextPageUrl}}
  <li class="next">
    <a href="#">Next &rarr;</a>
  </li>
  {{else}}
  <li class="next disabled">
    Next &rarr;
  </li>
  {{/if}}
</ul>
"""