
getContentAndTokenize = (tabId, tab, contentInfo) ->
  if tab.url.indexOf('http') != 0
    return

  console.log "TOK:"
  console.log tab.url
  chrome.tabs.executeScript tabId, {code: 'window.document.documentElement.innerHTML'}, (results) ->
    html = results[0]
    if html? and html.length > 10
      $.ajax(
        type: 'POST',
        url: 'http://104.131.7.171/lda',
        data: { 'data': JSON.stringify( {'html': html} ) }
      ).success( (results) ->
        console.log 'lda'
        results = JSON.parse results
        vector = results['vector']
        content = {title: tab.title, url: tab.url, vector: results['vector'], topics: results['topics'], topic_vector: results['topic_vector'], size: results['size']}
        ContentInfo.db.insert(content)
      ).fail (a, t, e) ->
        console.log 'fail tokenize'
        console.log t

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.status != 'complete'
    return
  if tab.url.indexOf('http') != 0
    return

  console.log 'onUpdated ' + tabId
  console.log changeInfo

  TabInfo.db({url: tab.url}).remove(false)
  TabInfo.db({tab: tabId}).remove(false)
  TabInfo.db.insert({tab: tabId, url: tab.url, title: tab.title, closed: false})

  contentInfo = ContentInfo.db({url: tab.url}).first()
  if not contentInfo
    getContentAndTokenize(tabId, tab, contentInfo)

chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->

  console.log 'onRemoved ' + tabId
  console.log removeInfo

  tabInfo = TabInfo.db({tab: tabId}).order("date desc").first()
  if tabInfo
    TabInfo.db(tabInfo).update {closed: true, time: Date.now()}
  else
    console.log 'Tab closed before finished loading: ' + tabId

