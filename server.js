// .js
const express = require('express');
const app = express();
const PORT = 3000; 

app.get('/', (req, res) => {
    res.send('<h1>Control de Gastos funcionando! ¡Contenedor OK!</h1>');
});


app.listen(PORT, () => {
    console.log(`Servidor de Control de Gastos corriendo en puerto ${PORT}`);
});