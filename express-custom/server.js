const express = require('express');

// App
const app = express();
app.get('/', (req, res) => {
  res.send('Hello world\n');
});

app.listen(process.env.PORT);
console.log(`Running server`);