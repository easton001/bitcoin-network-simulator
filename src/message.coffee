class Message
    transit_time: ({latency,bandwidth}) =>
        latency + @size/bandwidth

exports.InvMessage = class InvMessage extends Message
    key: 'inv'

    constructor: (@inventory) ->
        @size = 9 + 32*@inventory.length

exports.GetdataMessage = class GetdataMessage extends Message
    key: 'getdata'

    constructor: (@inventory) ->
        @size = 9 + 32*@inventory.length

exports.BlockMessage = class BlockMessage extends Message
    key: 'block'

    constructor: (@block) ->
        @size = 70 + @block.size

exports.TxMessage = class TxMessage extends Message
    key: 'tx'

    constructor: (@transaction) ->
        @size = @transaction.size

exports.NotfoundMessage = class NotfoundMessage extends Message
    key: 'notfound'

    @constructor:(@inventory) ->
        @size = 9 + 32*@inventory.length
