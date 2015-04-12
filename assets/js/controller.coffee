
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
    .linkDistance (l) -> Math.pow(1.0 - l.value, 1) * 100

svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

render = () ->
  console.log 'rendering'
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
        .attr('r', 5)
        .style('fill', (d) ->
          if d.closed
            'LightBlue'
          else
            'RoyalBlue'
        )
        .call(force.drag)

  node.append('title')
      .text((d) -> d.title)

  force.on('tick', () ->
    link.attr('x1', (d) -> d.source.x)
        .attr('y1', (d) -> d.source.y)
        .attr('x2', (d) -> d.target.x)
        .attr('y2', (d) -> d.target.y)

    node.attr('cx', (d) -> d.x)
        .attr('cy', (d) -> d.y)
  )


$('.render').click render

