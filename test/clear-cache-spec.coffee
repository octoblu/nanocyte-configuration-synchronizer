{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'
crypto = require 'crypto'
hash = (flowData) -> crypto.createHash('sha256').update(flowData).digest 'hex'

describe 'Clear cache', ->

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done

  afterEach 'clean up mongo', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id', done

  beforeEach 'insert instances', (done) ->
    flowData = JSON.stringify
      'node-id':
        config: {foo: 'bar'}
        data:   {bar: 'foo'}

    @theHash = hash(flowData)

    @datastore.insert {
      flowId: 'flow-id'
      instanceId: 'instance-id'
      flowData: flowData
      hash: @theHash
    }, done

  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', "instance-id/hash/#{@theHash}", Date.now(), done

  beforeEach 'clearByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.clearByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should delete the key in redis', (done) ->
    @cache.hget 'flow-id', "instance-id/hash/#{@theHash}", (error, result) =>
      expect(result).not.to.exist
      done()
