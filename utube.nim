import httpClient
import strutils
import os

proc channelContent(channel:string):string =
  newHttpClient().getContent("https://www.youtube.com/"&channel&"/videos")

proc getUrl(handle,id:string):string =
  let 
    source = channelContent(handle)
    pos = source.find(id)
    urlStart = source.find('"',pos+id.high+2)
    urlEnd = source.find('"',urlStart+1)
  source[urlStart+1..urlEnd-1]

proc channel(default:string):string =
  for param in commandLineParams():
    if param.startsWith("@"):
      return param[1..param.high]
  default

let 
  uChannel = channel("@WeebUnionWU")
  channelRssUrl = getUrl(uChannel,"rssUrl")
  entries = newHttpClient().getContent(channelRssUrl).splitLines

echo getUrl(uChannel,"channelUrl")
for line in entries[7..entries.high]:
  let l = line.strip
  if l.startsWith("<link"):
    echo l[l.find("http")..l.find(">")-3]
  elif l.startsWith("<title>"):
    echo l["<title>".len..l.find("<",6)-1]
