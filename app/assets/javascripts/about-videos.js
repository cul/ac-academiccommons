$('.fancybox-media').fancybox({
		openEffect  : 'elastic',
		closeEffect : 'elastic',
		width: 640,
		height: 385,
		helpers : {
			media : {}
		}
	});
 
 
 $('.fancybox-counter').fancybox({
		openEffect  : 'elastic',
		closeEffect : 'elastic',
		width: 640,
		height: 385,
		helpers : {
			media : {}
		},
		beforeLoad: function(){
			
			 
		},
		
		beforeClose: function(){
		 
			 
			var url = window.location.pathname;
			var iuid = url.substring(url.lastIndexOf('/')+1);
			var counterURL = '/stats/counter/'+iuid;
			$.ajax({url:counterURL});


		},
	});
 