const express = require('express');
const router = express.Router();
const validUrl = require('valid-url');
const shortid = require('shortid');
const Url = require('../models/Url');

// @route     GET /healthcheck
// @desc      Health check endpoint

router.get('/healthcheck', (req, res) => {
  res.status(200).send('OK');
});


// @route     GET /:code
// @desc      Redirect to long/original URL
router.get('/:code', async (req, res) => {
  try {
    const urlBody = await Url.findOne({ urlCode: req.params.code });

    if (urlBody) {
      return res.redirect(urlBody.url);
    } else {
      return res.status(404).json('No url found');
    }
  } catch (err) {
    console.error(err);
    res.status(500).json('Server error');
  }
});


// @route     POST /newurl
// @desc      Create short URL
router.post('/newurl', async (req, res) => {
  const { url } = req.body;
  const baseUrl = process.env.BASEURL; // changed to env input

  // Check base url
  if (!validUrl.isUri(baseUrl)) {
    return res.status(401).json('Invalid base url');
  }

  // Create url code
  const urlCode = shortid.generate();

  // Check long url
  if (validUrl.isUri(url)) {
    try {
      let urlBody = await Url.findOne({ url });

      if (urlBody) {
        res.json(urlBody);
      } else {
        const shortUrl = baseUrl + '/' + urlCode;

        urlBody = new Url({
          url,
          shortUrl,
          urlCode,
          date: new Date()
        });

        await urlBody.save();

        res.json(urlBody);
      }
    } catch (err) {
      console.error(err);
      res.status(500).json('Server error');
    }
  } else {
    res.status(401).json('Invalid url');
  }
});


module.exports = router;
