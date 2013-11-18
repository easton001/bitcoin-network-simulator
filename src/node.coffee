_ = require('underscore')

{
    InvMessage,
    GetdataMessage,
    BlockMessage,
    TxMessage,
    NotfoundMessage,
} = require('./message')

{
    Block,
    genesis_block,
} = require('./block')

{
    event_loop
} = require('./event_loop')

exports.Node = class Node
    constructor: (@name) ->
        @connections = []
        @validation_speed = 1
        @current_chain = genesis_block
        @mempool = {}
        @neighbors = {}

    connect: (id, attrs) =>
        new Connection(@,@neighbors[id],attrs)

    connect_random: (attrs) =>
        ids = _.keys(@neighbors)
        ids.sort(-> Math.random() - 0.5)
        id = ids[0]
        @connect(id,attrs) if id

    handle_block: (block) =>
        if block.total_difficulty > @current_chain.total_difficulty
            @change_chain(block)
            @send_inv([{type:'block',hash:block.id}])

    change_chain: (new_chain) =>
        [old_chain, @current_chain] = [@current_chain, new_chain]
        @chain_changed(old_chain)

    chain_changed: (old_chain) =>
        common_ancestor = @current_chain.common_ancestor(old_chain)
        while (old_chain != common_ancestor)
            for transaction in old_chain.transactions
                @mempool[transaction.id] = transaction
            old_chain = old_chain.parent

        for id,transaction of @current_chain.all_transactions
            delete @mempool[id]

    send: (target_connection,message) =>
        for {connection,send} in @connections
            send(message) if connection == target_connection

    broadcast: (message) =>
        for {send} in @connections
            send(message)

    send_inv: (objects) =>
        @broadcast(new InvMessage(objects))

    inv: (connection,{inventory}) =>
        unknown = []
        for {type,hash} in inventory
            if type == 'block'
                unless hash of @current_chain.all_blocks
                    unknown.push({type, hash})
            else if type == 'transaction'
                unless hash of @current_chain.all_transactions
                    unknown.push({type, hash})
        if unknown.length > 0
            @send(connection,new GetdataMessage(unknown))

    getdata: (connection, {inventory}) =>
        missing = []
        for {type,hash} in inventory
            if type == 'block'
                if hash of @current_chain.all_blocks
                    @send(connection,new BlockMessage(@current_chain.all_blocks[hash]))
                else
                    missing.push({type,hash})
            else if type == 'transaction'
                if hash of @mempool
                    @send(connection, new TxMessage(@mempool[hash]))
                else
                    missing.push({type,hash})
        if missing.length > 0
            @send(connection,new NotfoundMessage(missing))

    block: (connection, {block}) =>
        @handle_block(block)

    tx: (connection, {transaction}) =>
        if transaction.valid(@current_chain,@mempool)
            @mempool[transaction.hash] = transaction
            @send_inv([{type:'transaction',hash:transaction.hash}])

exports.MiningNode = class MiningNode extends Node
    # Estimated number of diff 1 blocks per tick, at difficuty = 1 (stable network would sum to 1/10*60*1000)
    constructor: (name,@hashpower=1/(10*60*1000)) ->
        super(name)
        @blocks_mined = []
        @mine()

    mine: (parent=@current_chain,transactions=_.values(@mempool)) =>
        difficulty = parent.difficulty #TODO: Simulate difficulty adjustments.
        success_callback = =>
            return if @mining != success_callback
            @handle_minted_block(new Block(parent,transactions,difficulty,@name))
        @mining = success_callback
        runtime = -Math.log(Math.random()) / (@hashpower/difficulty)
        event_loop.schedule(success_callback, runtime)

    handle_minted_block: (block) =>
        # console.log("Minted new block #{block}")
        @blocks_mined.push(block)
        @handle_block(block) #No special prefetence to the fact that it's our block.

    chain_changed: (old_chain)=>
        super(old_chain)
        @mine()

    mining_stats: =>
        "#{@name}: #{_.filter(@blocks_mined,({id})=>id of @current_chain.all_blocks).length}/#{@blocks_mined.length}"

class Connection
    constructor: (@node1,@node2, attributes={}) ->
        {@latency,@bandwidth} = _.defaults(attributes, {
            latency: 100, #Milliseconds
            bandwidth: 7, #bytes/ms
        })
        @queue = []
        @pending = false

        for [start,end] in [[@node1, @node2], [@node2, @node1]]
            do (start,end) =>
                start.connections.push({
                    connection: @,
                    send: (message) =>
                        transit_time = message.transit_time({@latency,@bandwidth})
                        #console.log("[#{start.name}->#{end.name}] Queuing #{message.key} (ETA: #{transit_time}) @#{event_loop.ticks}")
                        @queue.push([(=>
                            #console.log("[#{start.name}->#{end.name}] Sent #{message.key} @#{event_loop.ticks}")
                            end[message.key](@,message)),
                            transit_time
                        ])
                        @process_queue()
                })

    process_queue: =>
        return if @pending
        return if @queue.length == 0
        [event,time] = @queue.shift()
        @pending = true
        event_loop.schedule((=>
            @pending = false
            event()
            @process_queue()
        ),time)
