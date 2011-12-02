express = require 'express'
eco = require 'eco'
samurai = require 'samurai'

samuraiConfig =
  sandbox:           true
  merchant_key:      'a1ebafb6da5238fb8a3ac9f6',
  merchant_password: 'ae1aa640f6b735c4730fbb56',
  processor_token:   '5a0e1ca1e5a11a2997bbf912'

samurai.setup samuraiConfig

app = express.createServer()

app.dynamicHelpers
  head: (req, res) ->
    do ->
      head = ''
      {
        append: (s) -> head += s()
        get: -> head
      }

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'eco'
  app.register '.eco', eco

  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')
  app.use express.errorHandler(dumpExceptions: true, showStack: true)

app.get '/', (req, res) ->
  res.render 'index'

app.get '/samurai_js/payment_form', (req, res) ->
  res.render 'samurai_js/payment_form', merchant_key: samuraiConfig.merchant_key

app.post '/samurai_js/purchase', (req, res) ->
  purchase = samurai.Processor.purchase(
    req.body.payment_method_token,
    122.00, # The price for the Samurai.js Katana Sword
    {
      descriptor: 'Samurai.js Katana Sword',
      customer_reference: +new Date(),
      billing_reference: +new Date()
    },
    (err, purchase) ->
      res.send JSON.stringify(transaction: purchase)
  )

app.get '/samurai_js/receipt', (req, res) ->
  res.render 'samurai_js/receipt'

app.listen(3000)
