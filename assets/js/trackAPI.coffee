###
#
# API used for parsing the information stored in chrome.storage for searches
#
###


DB_SIZE = 100
DB_LIMIT = 150

tabInfoThrottle = null
window.TabInfo = (() ->
  obj = {}
  obj.db = TAFFY()
  #Lets us track which running version of this file is actually updating the DB
  updateID = generateUUID()
  updateFunction = null
  _onDBChange = (_this) ->
    console.log 'onDBChange exec'
    size = TabInfo.db().get().length
    console.log '  dbSize ' + size
    if size > DB_LIMIT
      console.log 'persisting to file'
      spillCount = size - DB_SIZE
      console.log 'spilling ' + spillCount + ' records'
      old = TabInfo.db().order('time asec').limit(spillCount).get()
      TabInfo.db(old).remove()
    chrome.storage.local.set {'tabs': {db: _this, updateId: updateID}}

  settings =
    cacheSize: 0
    template: {}
    onDBChange: () ->
      console.log 'onDBChange tabInfoThrottle'
      clearTimeout(tabInfoThrottle)
      _this = this
      _exec = () -> _onDBChange(_this)
      tabInfoThrottle = setTimeout(_exec, 1500)

  #Grab the info from localStorage and lets update it
  chrome.storage.onChanged.addListener (changes, areaName) ->
    if changes.tabs?
      if !changes.tabs.newValue?
        obj.db = TAFFY()
        obj.db.settings(settings)
        updateFunction() if updateFunction?
      else if changes.tabs.newValue.updateid != updateID
        obj.db = TAFFY(changes.tabs.newValue.db, false)
        obj.db.settings(settings)
        updateFunction() if updateFunction?

  chrome.storage.local.get 'tabs', (retVal) ->
    if retVal.tabs?
      obj.db = TAFFY(retVal.tabs.db)
    obj.db.settings(settings)
    updateFunction() if updateFunction?

  obj.clearDB = () ->
    chrome.storage.local.remove('tabs')
    obj.db = TAFFY()
    console.log 'deleting spill files'

  obj.db.settings(settings)
  obj.updateFunction = (fn) -> updateFunction = fn

  return obj
)()

contentInfoThrottle = null
window.ContentInfo = (() ->
  obj = {}
  obj.db = TAFFY()
  #Lets us track which running version of this file is actually updating the DB
  updateID = generateUUID()
  updateFunction = null
  _onDBChange = (_this) ->
    console.log 'onDBChange exec'
    size = ContentInfo.db().get().length
    console.log '  dbSize ' + size
    if size > DB_LIMIT
      console.log 'persisting to file'
      spillCount = size - DB_SIZE
      console.log 'spilling ' + spillCount + ' records'
      old = ContentInfo.db().order('time asec').limit(spillCount).get()
      ContentInfo.db(old).remove()
    chrome.storage.local.set {'contents': {db: _this, updateId: updateID}}

  settings =
    cacheSize: 0
    template: {}
    onDBChange: () ->
      console.log 'onDBChange contentInfoThrottle'
      clearTimeout(contentInfoThrottle)
      _this = this
      _exec = () -> _onDBChange(_this)
      contentInfoThrottle = setTimeout(_exec, 1500)

  #Grab the info from localStorage and lets update it
  chrome.storage.onChanged.addListener (changes, areaName) ->
    if changes.contents?
      if !changes.contents.newValue?
        obj.db = TAFFY()
        obj.db.settings(settings)
        updateFunction() if updateFunction?
      else if changes.contents.newValue.updateid != updateID
        obj.db = TAFFY(changes.contents.newValue.db, false)
        obj.db.settings(settings)
        updateFunction() if updateFunction?

  chrome.storage.local.get 'contents', (retVal) ->
    if retVal.contents?
      obj.db = TAFFY(retVal.contents.db)
    obj.db.settings(settings)
    updateFunction() if updateFunction?

  obj.clearDB = () ->
    chrome.storage.local.remove('contents')
    obj.db = TAFFY()
    console.log 'deleting spill files'

  obj.db.settings(settings)
  obj.updateFunction = (fn) -> updateFunction = fn

  return obj
)()

