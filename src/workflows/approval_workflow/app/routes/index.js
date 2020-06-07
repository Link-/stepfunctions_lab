var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { 
    title: 'Approval Workflow Controller',
    env: JSON.stringify(process.env)
  });
});

module.exports = router;
