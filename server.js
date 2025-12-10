// .js
const express = require('express');
const app = express();
const PORT = 3000; // ¡Asegúrate de que este puerto coincida con tu mapeo de Docker!

app.get('/', (req, res) => {
    res.send('<h1>Control de Gastos funcionando! ¡Contenedor OK!</h1>');
});

// Esta línea es CRUCIAL para que el servidor se mantenga activo
app.listen(PORT, () => {
    console.log(`Servidor de Control de Gastos corriendo en puerto ${PORT}`);
});