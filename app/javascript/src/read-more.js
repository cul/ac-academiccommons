$(document).ready(function(){
  $('#document .blacklight-author_ssim').readmore({
  collapsedHeight: 25,
  lessLink: '<a href="#">View fewer authors</a>',
  moreLink: '<a href="#">View all authors</a>',
  blockCSS: 'display: inline-block; width: auto;'
  });

  $('.featured-searches .featured-search .description').readmore({
  collapsedHeight: 0,
  lessLink: '<a href="#">Read less</a>',
  moreLink: '<a href="#">Read more</a>',
  embedCSS: 'false'
  });
});
