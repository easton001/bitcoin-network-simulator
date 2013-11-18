_ = require('underscore')

{
    MiningNode,
    Node
} = require('./node')

{
    event_loop
} = require('./event_loop')

{
    Block
} = require('./block')

miners = (new MiningNode("miner" + i, 1 / (100*10*60*1000)) for i in [1..100])
full_nodes = (new Node("fullnode" + i) for i in [1..900])

all_nodes = {}
for node in miners.concat(full_nodes)
    node.neighbors = _.clone(all_nodes)
    all_nodes[node.name] = node

for node in _.values(all_nodes)
    for i in [0..Math.ceil(Math.random() * 2)]
        node.connect_random({latency: 100})

event_loop.run_synchronous(7*24*60*60*1000)
for miner in miners
    console.log(miner.mining_stats())
