const 
  startHTML* = """
<!DOCTYPE html>
<html>
  <head>
		<meta charset="utf8">
		<meta name="viewport" content="width=device-width">
		<style type="text/css">
			body {
				background-color: #1B0C0C;
			}
			img {
				padding: 0px 10px 0px 0px;
			}
      a:link {
        text-decoration: none;
      }

      a:visited {
        text-decoration: none;
      }
      a:hover {
        color: darkgoldenrod;
        text-decoration: underline;
      }
      a:active {
        text-decoration: none;
      }			
      #textArea {
				padding: 1px 1px 1px 10px;
				width: 95%;
				border-style: inset;
				border: 3px groove;
				border-radius: 5px;
				border: 1px solid black;
				background-color: rgb(27, 27, 27);
				border-radius: 5px;
			}
			h1 {
				color: darkgoldenrod;
				font-family: Ariel;
				font-size: medium;
			}
			h2 {
				color: magenta;
				font-family: Ariel;
				font-size: large;
			}
		</style>
  </head>
  <body>
"""
  endHTML* = """
  </body>
</html>
"""
  startRssHTML* = """<div id="textArea">"""
  endRssHTML* = """</div>"""
