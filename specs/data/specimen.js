jQuery.cookie = function(name, value, options) {
    if (typeof value != 'undefined') { // name and value given, set cookie
        options = options || {};
        if (value === null) {
            value = '';
            options.expires = -1;
        }
        var expires = '';
        if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
            var date;
            if (typeof options.expires == 'number') {
                date = new Date();
                date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
            } else {
                date = options.expires;
            }
            expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
        }
        var path = options.path ? '; path=' + (options.path) : '';
        var domain = options.domain ? '; domain=' + (options.domain) : '';
        var secure = options.secure ? '; secure' : '';
        document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
    } else { // only name given, get cookie
        var cookieValue = null;
        if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
                var cookie = jQuery.trim(cookies[i]);
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, name.length + 1) == (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
};
if($.cookie("css")) {
	$("link").attr("href",$.cookie("css"));
}

/* Analytics stuff */
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-1533406-1']);
ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);

var ads_ready_to_swap = true;
function update_ads() {
	if (!ads_ready_to_swap) return;
	ads_ready_to_swap = false;

	$('.header iframe').attr('src', 'http://www.fakku.net/static/footer.html');
	$('#bottom iframe').attr('src', 'http://www.fakku.net/static/header.html');
	setTimeout(function() { ads_ready_to_swap = true; }, 8000);
}
$(document).ready(function() { 
	$(".styleswitch").click(function() { 
		$("link").attr("href",$(this).attr('rel'));
		$.cookie("css",$(this).attr('rel'), {expires: 365, path: '/'});
		return false;
	});

	var data = {"meta":{"content_active":"1","0":"1","section":"a","1":"a","name":"Angel Yard Chapter 2","2":"Angel Yard Chapter 2","folder":"angelyardchapter2_e","3":"angelyardchapter2_e","series_name":"Original Work","4":"Original Work","artist_name":"Otono Natsu","5":"Otono Natsu","language":"English","6":"English","thumbnails":null,"7":null,"next_chapter":null,"8":null,"content_id":"7009","dir":"manga\/a\/angelyardchapter2_e\/","thumbs":"manga\/a\/angelyardchapter2_e\/thumbs\/"},"thumbs":["manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 001.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 002.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 003.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 004.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 005.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 006.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 007.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 008.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 009.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 010.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 011.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 012.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 013.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 014.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 015.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 016.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 017.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 018.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 019.thumb.jpg","manga\/a\/angelyardchapter2_e\/thumbs\/[Otono Natsu] Original Work - Angel Yard Chapter 2 (English) 020.thumb.jpg"]};
	var manga = data.meta;
	var thumbs = data.thumbs;

	function get_params() {
		var params = {};

		/* Pull all the search parameters */
		var tmp = window.location.search.substr(1).split('&');
		for (var i in tmp) {
			var tmp2 = tmp[i].split('=');
			params[tmp2[0]] = unescape(tmp2[1]);
		}

		/* Then also throw in the hash values over the query string */
		var tmp = window.location.hash.substr(1).split('&');
		for (var i in tmp) {
			var tmp2 = tmp[i].split('=');
			params[tmp2[0]] = unescape(tmp2[1]);
		}

		/* Also fix the page number */
		if (thumbs) {
			var page = parseInt(params.page);
			if (isNaN(page)) page = 0;

			if (page < 0)
				params.page = thumbs.length;
			else if (page == 0)
				params.page = 'thumbs';
			else if (page <= thumbs.length)
				params.page = page;
			else
				params.page = 'thumbs';
		}

		return params;
	}

	var params = get_params();

	function update_page() {
		_gaq.push('_trackPageview');
		update_ads();

		$('html, body').animate({scrollTop:0}, 'fast');

		var params = get_params();

		$('#loading').show();

		if (!params['page'] || params['page'] == 'thumbs') {
			/* Display the thumbnail view */
			$('#thumbs').empty();

			$.each(thumbs, function(i, x) {
				var title = '(Page ' + i + ')';
				var row = ('<a href="#page=' + (i + 1) + '" title="' + title + '"><img src="http://cdn.fakku.net/8041E1/t/' + x + '" alt="' + title + '" height="140" width="100" class="thumb"/></a>');
				/*
				row += ('<a style="display: none;">href="#page=' + (i + 1) + '" title="' + title + '"><img src="http://tower.unshield.org/t/' + x + '" alt="' + title + '" height="140" width="100" class="thumb"/></a>');
				*/
				$('#thumbs').append(row);
			});

			$('#loading').hide();
			$('#thumbs').show();
			$('#image').hide();
		}
		else {
			function imgpath(x, tower) {
				/* Gross way of padding the integer */
				x = '' + x;
				while (x.length < 3)
					x = '0' + x;
				/*
				if (tower) {
					var mirror = 'http://tower.unshield.org/m/';
				}
				else {
					var mirror = 'http://cdn.fakku.net/8041E1/c';
				}
				*/


				var mirror = 'http://cdn.fakku.net/8041E1/c';
				return mirror + '/manga/' + manga.section + '/' + manga.folder + '/images/' + x + '.jpg';
			}

			var p = parseInt(params['page']);

			if (p > thumbs.length) {
				window.location.hash = '#thumbs';
				return;
			}

			$('#image').empty();
			$('#image').append('<a href="#page=' + (p + 1) + '" title="Next Page"><img src="' + imgpath(p) + '"/></a>');
			$('#image').append('<img src="' + imgpath(p, true) + '" style="display: none;"/>');

			if (p + 1 < thumbs.length) {
				$('#image').append('<img src="' + imgpath(p + 1) + '" style="display: none;"/>');
			}

			$('.drop').val(p);
			$('#loading').hide();
			$('#thumbs').hide();	
			$('#image').show();
		}
	}

	setInterval
		(
			(function() {
				var lasthash = window.location.hash;
				return function() {
					var tmp = window.location.hash;
					if (tmp != lasthash) {
						lasthash = tmp;
						update_page();
					}
				};
				})()
		, 1000
		);

	$('.related_manga').change(function() {
		document.location = '/viewmanga.php?id=' + $(this).val() + '#';
	});
	$('#related').change(function() {
		window.location = '?id=' + $(this).val();	
	});

	$('.drop').change(function() {
		window.location.hash = '#page=' + $(this).val();
	});

	function change_page(inc) {
		var params = get_params();
		var page = parseInt(params.page);
		if (isNaN(page)) page = 0;
		page += inc;

		if (page < 0)
			window.location.hash = '#page=' + thumbs.length;
		else if (page == 0)
			window.location.hash = '#page=thumbs';
		else if (page <= thumbs.length)
			window.location.hash = '#page=' + page;
		else
			window.location.hash = '#page=thumbs';
	}

	$(document).keydown(function(ev) {
		if (ev.keyCode == 37) {
			change_page(-1);
			return false;
		}
		else if (ev.keyCode == 39) {	
			change_page(1);
			return false;
		}
	});

	$('.next a').click(function() {
		change_page(1);
	});

	$('.prev a').click(function() {
		change_page(-1);
	});

	$.each(thumbs, function(i, x) {
		$('.drop').append('<option value="' + (i + 1) + '">Page ' + (i + 1) + '</option>');
	});

	$('a.a-series')
		.attr('title', manga.series_name + ' hentai manga and doujinshi')
		.attr('href', '/manga.php?series=' + escape(manga.series_name))
		;

	$('a.a-series-title')
		.attr('title', manga.series_name + ' - ' + manga.name + ' - Download & View Online')
		.attr('href', '/viewmanga.php?id=' + manga.content_id)
		;

	$('a.a-language')
		.attr('title', manga.language + ' hentai manga and doujinshi')
		.attr('href', '/manga/' + manga.language.toLowerCase())
		.text(manga.language)
		;

	$('.series').text(manga.series_name);
	$('.manga-title').text(manga.name);

	$('.postload').show();

	update_page();
	$('body').focus();
});
