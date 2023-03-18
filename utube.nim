import httpClient
import strutils
import os

proc content(channel:string):string =
  newHttpClient().getContent("https://www.youtube.com/"&channel&"/videos")

proc getUrl(channel,urlId:string):string =
  let 
    source = channel.content
    pos = source.find(urlId)
    urlStart = source.find('"',pos+urlId.high+2)
    urlEnd = source.find('"',urlStart+1)
  source[urlStart+1..urlEnd-1]

proc channel(default:string):string =
  for param in commandLineParams():
    if param.startsWith("@"): return param
  default

let 
  uChannel = channel("@WeebUnionWU")
  channelRssUrl = getUrl(uChannel,"rssUrl")
  entries = newHttpClient().getContent(channelRssUrl).splitLines

echo getUrl(uChannel,"channelUrl")
for line in entries[7..entries.high]:
  let l = line.strip
  if l.startsWith("<link"):
    echo l[l.find("http")..l.find('>')-3]
  elif l.startsWith("<title>"):
    echo l["<title>".len..l.find("<",6)-1]
