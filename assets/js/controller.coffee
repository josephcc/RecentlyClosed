
width = null
height = null
force = null

getSize = () ->
  w = window
  d = document
  e = d.documentElement
  g = d.getElementsByTagName('body')[0]
  width = w.innerWidth || e.clientWidth || g.clientWidth
  height = w.innerHeight|| e.clientHeight|| g.clientHeight
  width = width - 10
  height = height - 10
  return [width, height]

dot = (v1, v2) ->
  v = _.map _.zip(v1, v2), (xy) -> xy[0] * xy[1]
  v = _.reduce v, (x, y) -> x + y
  v

mag = (v) ->
  v = _.map v, (x) -> x*x
  out = _.reduce v, (x, y) -> x + y
  Math.sqrt(out)

cosine = (v1, v2) ->
  dot(v1, v2) / (mag(v1) * mag(v2))

scale = (v, factor) ->
  _.map v, (s) -> s*factor

stack = (v1, v2) ->
  v = _.map _.zip(v1, v2), (xy) -> xy[0] + xy[1]

graph = {nodes: [], links: []}
render = () ->
  _.each graph.nodes, (node) ->
    TabInfo.db({url: node.url}).update({px: node.px, py: node.py, x: node.x, y: node.y}, false)
  $('svg').remove()

  svg = d3.select('body').append('svg')
      .attr('width', width)
      .attr('height', height)
  console.log 'rendering'
  now = Date.now()
  graph = {nodes: TabInfo.db().get(), links: []}
  _.each graph.nodes, (node1, index1) ->
    _.each graph.nodes, (node2, index2) ->
      if index2 > index1 
        content1 = ContentInfo.db({url: node1.url}).first()
        content2 = ContentInfo.db({url: node2.url}).first()
        if content1 and content2
          similarity = cosine(content1.topic_vector, content2.topic_vector)
        else
          similarity = 0.0
        if similarity <= 0.1
          similarity = 0.0
        graph.links.push {source: index1, target: index2, value: similarity}

  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start()

  link = svg.selectAll('.link')
        .data(graph.links)
        .enter().append('line')
        .attr('class', 'link')
        .style('stroke-width', (d) -> 10 + d.value * 5)

  focusNode = (d) ->
    if d.closed
      window.open(d.url, '_blank')
    else
      chrome.tabs.get(d.tab, (tab) ->
        chrome.windows.update(tab.windowId, {focused: true})
        chrome.tabs.update(d.tab, {selected: true})
      )

  node = svg.selectAll('.node')
        .data(graph.nodes)
        .enter().append('circle')
        .attr('class', 'node')
        .attr('r', nodeForR)
        .style('cursor', 'pointer')
        .style('fill', (d) ->
          if d.closed
            'SlateGray'
          else
            'DeepSkyBlue'
        )
        .on('click', focusNode)
  node.append('title')
      .text((d) -> d.url)

  image = svg.selectAll("image.favicon")
  image = image.data(graph.nodes)
  image.enter().append("svg:image")
        .attr("class", "favicon")
        .attr("xlink:href",(d) -> 'chrome://favicon/' + d.url)
        .on('click', focusNode)
        .style('cursor', 'pointer')

  text = svg.selectAll("text.label")
  text = text.data(graph.nodes)
  text.enter().append("text")
        .attr("class", "label")
        .attr("fill", 'lightgray')
        .text((d) -> d.title.substring(0, 20))

  distanceToMouse = (d) ->
    Math.pow(Math.pow(mouse.x - d.x, 2) + Math.pow(mouse.y - d.y, 2), 0.5)

  mouseZoom = (node, d1, d2, r, R) ->
    distance = distanceToMouse({x: node.x, y: node.y}) 
    x = distance - d2
    dd = d1 - d2
    dr = R - r
    if distance >= d1
      return r
    if distance <= d2
      return R
    return r + (dr * Math.pow( 1 - (x*x/(dd*dd)), 0.5))


  nodeForR = (d) ->
    if d.closed
      factor = 25
      age = (now - d.time)/1000/60/factor
      age = 15/age
      age = Math.max(3, age)
      age = Math.min(19, age)
      mouseZoom(d, 200, 20, age, 20)
    else
      20

  mouse = {x: 0, y: 0}
  tick = () ->

    link.attr('x1', (d) -> d.source.x)
        .attr('y1', (d) -> d.source.y)
        .attr('x2', (d) -> d.target.x)
        .attr('y2', (d) -> d.target.y)

    node.attr('cx', (d) -> d.x)
        .attr('cy', (d) -> d.y)
        .attr('r', nodeForR)


    image.attr("transform", (d) ->
      r = nodeForR(d)
      h = Math.min(r, 12)
      "translate(" + (d.x - 1) + "," + (d.y - 1) + ")"
    )
      .attr('width', (d) -> 
        nodeForR(d)
          #Math.max(8, nodeForR(d))
      )
      .attr('height', (d) -> 
        nodeForR(d)
          #Math.max(8, nodeForR(d))
      )

    text.attr("transform", (d) ->
      r = nodeForR(d)
      h = Math.min(r, 12)
      "translate(" + (d.x + r + 2) + "," + (d.y + (r/2) - (h/3)) + ")"
    )
    .style('font-size', (d) ->
      r = nodeForR(d)
      Math.min(r, 12)
    )
    .text((d) -> 
      r = nodeForR(d)
      if distanceToMouse(d) <= 150/3 or not d.closed
        d.title
      else
        ""
    )

  force.on('tick', tick)
  svg.on('mousemove', () ->
     mouse.x = d3.mouse(this)[0]
     mouse.y = d3.mouse(this)[1]
     tick()
  )

$(window).load () ->

  [width, height] = getSize()
  force = d3.layout.force()
    .size([width, height])
    .friction(0.0)
    .linkDistance (l) -> (20*12) + (Math.pow(1.0 - l.value, 2) * 300)
  
  chrome.tabs.query {windowType: 'normal'}, (tabs) ->
    openedUrls = []
    for tab in tabs
      openedUrls.push tab.url
      TabInfo.db({url: tab.url}).update({closed: false})
    console.log 'openedUrls'
    console.log openedUrls
    opened = TabInfo.db({closed: false}).get()
    console.log 'openedtabs'
    console.log opened
    _.each opened, (info) ->
      if not _.contains openedUrls, info.url
        TabInfo.db(info).update({closed: true, time: Date.now()})
    TabInfo.updateFunction(render)
    ContentInfo.updateFunction(render)
    render()
  
  $('body').css('background', '#1f1f1f')
