import asyncdispatch
import httpClient
import strutils
import sequtils
import os

const channelsFile = "channels.txt"
type RssEntry = tuple[header,name,time,url:string]

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

func rssFieldsFilled(rssItem:RssEntry):bool =
  for field in rssItem.fields:
    if field.len == 0: return
  return true

func parseEntries(rssLines:openArray[string],max:int):seq[RssEntry] =
  var newRssEntry:RssEntry
  result.add newRssEntry
  for line in rssLines[9..rssLines.high]:
    let ls = line.strip
    if ls.startsWith("<title>"):
      result[^1].header = ls["<title>".len..ls.find("<",6)-1]
    elif ls.startsWith("<name>"):
      result[^1].name = ls["<name>".len..ls.find("<",6)-1]
    elif ls.startsWith("<updated>"):
      result[^1].time = ls["<updated>".len..ls.find("T",6)-1]
    elif ls.startsWith("<link"):
      result[^1].url = ls[ls.find("http")..ls.find('>')-3]
    if result[^1].rssFieldsFilled:
      if result.len == max: return else: result.add newRssEntry
  if not result[^1].rssFieldsFilled: result.setLen(result.len-1)

proc channelsUrls(fileName:string):seq[string] =
  for line in lines(fileName): result.add line.channelUrl

proc urlFuture(url:string):Future[string] {.async.} =
  return await newAsyncHttpClient().getContent(url)

proc urlsContent(urls:openArray[string]):seq[string] =
  waitFor all urls.mapIt(it.urlFuture)

proc allLatestChannelsEntries(fileName:string):seq[RssEntry] =
  channelsUrls(fileName)
  .urlsContent()
  .mapIt(it.parseUrl("rssUrl"))
  .urlsContent()
  .mapIt(it.splitLines.parseEntries(1)[0])

proc allChannelEntries(prmChannel:string):seq[RssEntry] =
  let
    http = newHttpClient()
    channelContent = http.getContent channelUrl prmChannel
    channelRssUrl = channelContent.parseUrl("rssUrl")
    rssLines = http.getContent(channelRssUrl).splitLines
  echo channelRssUrl  
  rssLines.parseEntries(-1)

proc write(channelEntries:seq[RssEntry])

let prmChannel = paramChannel("channelsFile")
if prmChannel == "channelsFile":
  write allLatestChannelsEntries(channelsFile)
else:
  write allChannelEntries(prmChannel)

import terminal
proc write(channelEntries:seq[RssEntry]) =
  for entry in channelEntries:
    stdout.styledWrite fgYellow,entry.name&": "
    stdout.styledWrite fgBlue,entry.time&": "
    stdout.styledWriteLine fgYellow,entry.header
    stdout.styledWriteLine fgMagenta,entry.url
