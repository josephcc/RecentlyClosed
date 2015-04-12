
width = 1280
height = 800
color = d3.scale.category20()

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

force = d3.layout.force()
    .size([width, height])
    .charge(-120)
    .linkDistance (l) -> (20*3) + (Math.pow(1.0 - l.value, 2) * 300)

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
          similarity = 0.5
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

  node = svg.selectAll('.node')
        .data(graph.nodes)
        .enter().append('circle')
        .attr('class', 'node')
        .attr('r', nodeForR)
        .style('fill', (d) ->
          if d.closed
            'LightBlue'
          else
            'RoyalBlue'
        )
        .call(force.drag)
  node.append('title')
      .text((d) -> d.url)

  text = svg.selectAll("text.label")
  text = text.data(graph.nodes)
  text.enter().append("text")
        .attr("class", "label")
        .attr("fill", 'darkgray')
        .text((d) -> d.title)


  nodeForR = (d) ->
    if d.closed
      factor = 5
      age = (now - d.time)/1000/60/factor
      age = Math.max(1, age)
      15/age
    else
      20

  force.on('tick', () ->
    link.attr('x1', (d) -> d.source.x)
        .attr('y1', (d) -> d.source.y)
        .attr('x2', (d) -> d.target.x)
        .attr('y2', (d) -> d.target.y)

    node.attr('cx', (d) -> d.x)
        .attr('cy', (d) -> d.y)
        .attr('r', nodeForR)

    text.attr("transform", (d) ->
      r = nodeForR(d)
      "translate(" + (d.x + r + 2) + "," + (d.y + 3) + ")"
    )
  )


TabInfo.updateFunction(render)
ContentInfo.updateFunction(render)

