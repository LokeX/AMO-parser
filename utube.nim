import asyncdispatch
import httpClient
import threadPool
import uthtml
import strutils
import sequtils
import browsers
import os

const channelsFile = "channels.txt"

type 
  RssEntry = tuple[header,name,time,url,nail:string]
  PrmSet = tuple 
    browser,delete:bool
    channel,fileName:string
    maxEntries:int

proc getPrmSet:PrmSet =
  for param in commandLineParams():
    case param[0]
    of '@': result.channel = param.toLower
    of '-':
      case param[1]
      of 'b':result.browser = true
      of 'd':result.delete = true
      else: discard
    else:
      try: result.maxEntries = param.parseInt except: 
        result.fileName = param&".txt"
  if result.fileName.len == 0: 
    result.fileName = channelsFile

func channelUrl(channel:string):string =
  "https://www.youtube.com/"&channel&"/videos"

func parseUrl(channelContent,urlId:string):string =
  let 
    pos = channelContent.find(urlId)
    urlStart = channelContent.find('"',pos+urlId.high+2)
    urlEnd = channelContent.find('"',urlStart+1)
  channelContent[urlStart+1..urlEnd-1]

func rssFieldsFilled(rssItem:RssEntry):bool =
  for field in rssItem.fields:
    if field.len == 0: return
  return true

func parseEntries(rss:string,maxEntries:int):seq[RssEntry] =
  let rssLines = rss.splitLines
  var newRssEntry:RssEntry
  result.add newRssEntry
  for line in rssLines[9..rssLines.high]:
    let ls = line.strip
    if ls.startsWith "<title>":
      result[^1].header = ls["<title>".len..ls.find("<",6)-1]
    elif ls.startsWith "<name>":
      result[^1].name = ls["<name>".len..ls.find("<",6)-1]
    elif ls.startsWith "<updated>":
      result[^1].time = ls["<updated>".len..ls.find("T",6)-1]
    elif ls.startsWith "<link":
      result[^1].url = ls[ls.find("http")..ls.find('>')-3]
    elif ls.startsWith "<media:thumbnail":
      result[^1].nail = ls[ls.find("http")..ls.find('"',25)-1]
    if result[^1].rssFieldsFilled:
      if result.len == maxEntries: 
        return 
      result.add newRssEntry
  result.setLen result.len-1

proc urlFuture(url:string):Future[string] {.async.} =
  return await newAsyncHttpClient().getContent url

proc urlsGetContent(urls:openArray[string]):seq[string] =
  waitFor all urls.mapIt it.urlFuture

func flatMap[T](x:seq[seq[T]]):seq[T] =
  for y in x:
    for z in y:
      result.add z

func generateHTML(rssEntries:openArray[RssEntry]):string =
  result.add startHTML
  for rssEntry in rssEntries:
    result.add startRssHTML
    result.add "<a href = \""&rssEntry.url&"\">"
    result.add "<img src = \""&rssEntry.nail&"\" width = \"100\" style = \"float:left;\">"
    result.add "<h2>"&rssEntry.name&": "&rssEntry.time&"</h2>"
    result.add "<h1>  "&rssEntry.header&"</h1>"
    result.add "</a>"
    result.add endRssHTML
    result.add "\n"
  result.add endHTML

proc channelsFileWith(prmSet:PrmSet):seq[string] =
  if fileExists prmSet.fileName:
    for line in lines prmSet.fileName: result.add line
  if prmSet.delete: 
    result = result.filterIt(it != prmSet.channel) 
  elif prmSet.channel.len > 0 and result.find(prmSet.channel) == -1: 
    result.add prmSet.channel

proc allChannelsEntries(channels:openArray[string],maxEntries:int):seq[RssEntry] =
  channels.mapIt(it.channelUrl)
  .urlsGetContent
  .mapIt(spawn it.parseUrl "rssUrl")
  .mapIt(^it)
  .urlsGetContent
  .mapIt(spawn it.parseEntries(if maxEntries < 1: 1 else: maxEntries))
  .mapIt(^it)
  .flatMap

proc channelEntries(prmChannel:string,maxEntries:int):seq[RssEntry] =
  let
    http = newHttpClient()
    channelContent = http.getContent channelUrl prmChannel
    channelRssUrl = channelContent.parseUrl "rssUrl"
    rssLines = http.getContent(channelRssUrl)
  echo channelRssUrl  
  rssLines.parseEntries maxEntries

proc write(channelEntries:seq[RssEntry])

template init(prmSet,uChannels,rssEntries,codeBlock:untyped) =
  let 
    prmSet = getPrmSet()
    uChannels = channelsFileWith prmSet
    rssEntries = 
      if prmSet.delete or prmSet.channel.len == 0:
        allChannelsEntries uChannels,prmSet.maxEntries
      else: channelEntries prmSet.channel,prmSet.maxEntries
  codeBlock

init(params,channels,entries):
  if params.browser: 
    writeFile "utube.html",generateHTML entries
    openDefaultBrowser "utube.html"
  else: write entries
  writeFile params.fileName,channels.join("\n")
  echo params

import terminal
proc write(channelEntries:seq[RssEntry]) =
  for entry in channelEntries:
    stdout.styledWrite fgYellow,entry.name&": "
    stdout.styledWrite fgBlue,entry.time&": "
    stdout.styledWriteLine fgYellow,entry.header
    stdout.styledWriteLine fgMagenta,entry.url
