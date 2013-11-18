_ = require('underscore')

{event_loop} = require('./event_loop')

{
    CoinbaseTransaction
} = require('./transaction')

unique_id = (->
    next = -1
    => 'block-' + (next += 1)
)()

exports.Block = class Block
    constructor: (@parent,transactions,@difficulty,@mined_by) ->
        @id = unique_id()
        @size = _.inject(@transactions, ((total,{size}) -> total+size), 0)
        @total_difficulty = @difficulty + (@parent?.total_difficulty ? 0)
        @height = (@parent?.height ? 0) + 1
        @all_blocks = {}
        @all_blocks[@id] = @
        @creation_time = event_loop.ticks

        @transactions = _.clone(transactions)
        @transactions.shift(new CoinbaseTransaction())
        @all_transactions = _.clone(@parent?.all_transactions ? {})

        @valid = (not @parent?) or @parent.valid

        for transaction in @transactions
            for dep in transaction.depends_on
                unless @all_transactions[dep.id]
                    @valid = false
                    break
            for conflict in transaction.conflicts_with
                if @all_transactions[conflict.id]
                    @valid = false
                    break
            @all_transactions[transaction.id] = transaction

        _.defaults(@all_blocks,@parent?.all_blocks ? {})
        Block.all_blocks.push(@)

    common_ancestor: (other) =>
        self = @
        while self.height > other.height
            self = self.parent
        while other.height > self.height
            other = other.parent
        while (self != other)
            self = self.parent
            other = other.parent
        return self

    toString: =>
        "[Block #{@id}@#{@height} by #{@mined_by}@#{@creation_time} on top of #{@parent?.id}]"

    full_chain: =>
        (@parent?.full_chain?() ? []).concat([@])

    @all_blocks: []

exports.genesis_block = genesis_block = new Block(null,[],1,'Satoshi')
