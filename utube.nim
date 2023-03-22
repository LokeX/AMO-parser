import asyncdispatch
import httpClient
import strutils
import sequtils
import os

const channelsFile = "channels.txt"

func channelUrl(channel:string):string =
  "https://www.youtube.com/"&channel&"/videos"

func parseUrl(channelContent,urlId:string):string =
  let 
    pos = channelContent.find(urlId)
    urlStart = channelContent.find('"',pos+urlId.high+2)
    urlEnd = channelContent.find('"',urlStart+1)
  channelContent[urlStart+1..urlEnd-1]

proc fileLines(prm:string):string =
  if fileExists(channelsFile):
    for line in lines(channelsFile): result.add line&"\n"
    if result.find(prm) == -1: result.add prm&"\n"

proc paramChannel(default:string):string =
  for param in commandLineParams():
    if param.startsWith("@"): 
      try: 
        discard newHttpClient().getContent(channelUrl param)
      except: return default
      writeFile(channelsFile,fileLines(param.toLower))
      return param
  default

func parseEntries(rssLines:openArray[string]):(seq[string],seq[string]) =
  for line in rssLines[7..rssLines.high]:
    let l = line.strip
    if l.startsWith("<title>"):
      result[0].add l["<title>".len..l.find("<",6)-1]
    elif l.startsWith("<link"):
      result[1].add l[l.find("http")..l.find('>')-3]

proc channelsUrls(fileName:string):seq[string] =
  for line in lines(fileName): result.add line.channelUrl

proc urlFuture(url:string):Future[string] {.async.} =
  return await newAsyncHttpClient().getContent(url)

proc urlsContent(urls:openArray[string]):seq[string] =
  waitFor all urls.mapIt(it.urlFuture)

func zipTuple[T,U](x:(seq[T],seq[U])):seq[(T,U)] = zip(x[0],x[1])

proc allLatestChannelsEntries(fileName:string):seq[(string,string)] =
  channelsUrls(fileName)
  .urlsContent()
  .mapIt(it.parseUrl("rssUrl"))
  .urlsContent()
  .mapIt(parseEntries(it.splitLines).zipTuple[0])

proc allChannelEntries(prmChannel:string):seq[(string,string)] =
  let
    http = newHttpClient()
    channelContent = http.getContent channelUrl prmChannel
    channelRssUrl = channelContent.parseUrl("rssUrl")
    rssLines = http.getContent(channelRssUrl).splitLines
  echo channelRssUrl  
  rssLines.parseEntries.zipTuple

proc write(rssItems:(string,string))

let prmChannel = paramChannel("channelsFile")
if prmChannel == "channelsFile":
  let latestChannelsEntries = allLatestChannelsEntries(channelsFile)
  for channelEntry in latestChannelsEntries: write channelEntry
else:
  let channelEntries = allChannelEntries(prmChannel)
  for channelEntry in channelEntries: write channelEntry

import terminal
proc write(rssItems:(string,string)) =
  let (header,url) = rssItems
  stdout.styledWriteLine fgYellow,header
  stdout.styledWriteLine fgMagenta,url
