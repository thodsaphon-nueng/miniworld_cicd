const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;



let password = process.env.PASSWORD || "simple"

app.get('/', (req, res) => {
    res.send('Hello from Express App! env.password: ' +password );
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});