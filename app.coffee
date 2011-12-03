samurai     = require 'samurai'
express     = require 'express'
eco         = require 'eco'
util        = require 'util'
querystring = require 'querystring'

# Configure Samurai.
# ------------------------------
samuraiConfig =
  sandbox:           true
  merchant_key:      'a1ebafb6da5238fb8a3ac9f6',
  merchant_password: 'ae1aa640f6b735c4730fbb56',
  processor_token:   '5a0e1ca1e5a11a2997bbf912'

samurai.setup samuraiConfig

# Start the express web server.
# ------------------------------
app = express.createServer()

app.helpers
  # Exposes the samurai object to the views.
  samurai: samurai,
  # Lets you append content to the <head> in the layout from inside the action views.
  head: do ->
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

# =============================================================================

app.get '/', (req, res) ->
  res.render 'index'

# Payment form for Samurai.js
# ------------------------------
#
# * displays a drop-in payment form from Samurai.js, no extra logic required
app.get '/samurai_js/payment_form', (req, res) ->
  res.render 'samurai_js/payment_form'

# Purchase action for Samurai.js
# ------------------------------
#
# * payment_method_token is POST'd via AJAX
# * Responds with a JSON transaction object
#
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

# Purchase confirmation & receipt page
# ------------------------------
app.get '/samurai_js/receipt', (req, res) ->
  res.render 'samurai_js/receipt'

# =============================================================================

# Payment form for Transparent Redirect 
# ------------------------------
#
# * Displays a payment form using the Samurai view helpers bundled in the samurai module.
# * Payment form is initialized with PaymentMethod data, if a token is passed in the request.
#   This allows validation & processor-response error messages to be displayed.
app.get '/transparent_redirect/payment_form', (req, res) ->
  if req.query.payment_method_token
    samurai.PaymentMethod.find req.query.payment_method_token,
      (err, paymentMethod) ->
        res.render 'transparent_redirect/payment_form',
                    redirectUrl: 'http://localhost:3000/transparent_redirect/purchase',
                    paymentMethod: paymentMethod
  else
    res.render 'transparent_redirect/payment_form',
                redirectUrl: 'http://localhost:3000/transparent_redirect/purchase'

# Purchase action for Transparent Redirect
# ------------------------------
#
# * This action is requested as the callback from the Samurai Transparent Redirect,
#   which is why it's a GET, instead of POST.
# * It performs the purchase, and redirects the user to the purchase confirmation page
# * On error, it redirects back to the payment form to display validation/card errors
#
app.get '/transparent_redirect/purchase', (req, res) ->
  return res.redirect('/transparent_redirect/payment_form') unless req.query.payment_method_token

  samurai.PaymentMethod.find req.query.payment_method_token,
    (err, paymentMethod) ->
      return res.redirect('/transparent_redirect/payment_form') unless paymentMethod
      
      samurai.Processor.purchase paymentMethod.token,
        122.00, # The price for the Transparent Redirect Nunchucks
        {
          descriptor: 'Transparent Redirect Nunchucks',
          customer_reference: +new Date(),
          billing_reference: +new Date()
        },
        (err, purchase) ->
          if purchase.isSuccess()
            res.redirect '/transparent_redirect/receipt'
          else
            qs = querystring.stringify(payment_method_token: paymentMethod.token)
            res.redirect '/transparent_redirect/payment_form?'+qs

# Purchase confirmation & receipt page
# ------------------------------
app.get '/transparent_redirect/receipt', (req, res) ->
  res.render 'transparent_redirect/receipt'

app.listen(3000)
