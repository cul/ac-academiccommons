$(document).ready(function(){
  new Readmore.default('#document .blacklight-author_ssim', {
  collapsedHeight: 25,
  lessLink: '<a href="#">View fewer authors</a>',
  moreLink: '<a href="#">View all authors</a>',
  blockCSS: 'display: inline-block; width: auto;'
  });

  new Readmore.default('.featured-searches .featured-search .description', {
  collapsedHeight: 0,
  lessLink: '<a href="#">Read less</a>',
  moreLink: '<a href="#">Read more</a>',
  embedCSS: 'false'
  });
});
