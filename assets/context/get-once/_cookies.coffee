###*
 * Get cookies
###
cookies: ->
	if cookieHeader = @req.headers.cookie
		secret= @settings.cookieSecret
		cookies= cookie.parse cookieHeader,
			decode: (data)->
				try
					data= decodeURIComponent data
					# decode cookie if it is
					if secret and data.startsWith 's'
						data = AESCrypto.decrypt(data.substr(1), secret).toString(CryptoJS.enc.Utf8)
					# parse json value
					if data.startsWith 'j'
						data= JSON.parse data.substr 1
					else
						data = data.substr 1
				catch e
					@warn 'Cookie-parser', e
				return data
	