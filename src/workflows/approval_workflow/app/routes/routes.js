var express = require('express');
var router = express.Router();

/* GET index */
router.get('/', function(req, res, next) {
  res.send(`
The following endpoints are available only:<br /><br />
<pre>
- GET /pending
  No body

- POST /approval
  Body:
  {
    approved: false|true
  }
</pre>
`);
});

/* GET orders pending approval. */
router.get('/pending', function(req, res, next) {
  res.send({ orders: '[1, 2, 3]' });
});

/* POST order decision */
router.post('/approval', function(req, rest, next) {
  res.send({ approved: true });
});

module.exports = router;
