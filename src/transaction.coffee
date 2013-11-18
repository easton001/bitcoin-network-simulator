txid = (->
    next = -1
    => 'tx-' + (next += 1)
)()

exports.Transaction = class Transaction
    constructor: (@size,@depends_on=[],@conflicts_with=[]) ->
        @id = txid()

exports.CoinbaseTransaction = class CoinbaseTransaction extends Transaction
    constructor: () ->
        super(128)
