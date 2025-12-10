// test.js
// Esto simula una prueba para verificar la lógica de la app

const assert = require('assert');

// Función simple a "probar"
function calcularBalance(ingresos, gastos) {
    // Si la aplicación fuera más compleja, esta función estaría en otro archivo (ej. utils.js)
    return ingresos - gastos;
}

// ----------------------------------------------------
// EJECUCIÓN DE PRUEBAS
// ----------------------------------------------------
console.log("Iniciando Pruebas Unitarias...");

// Prueba 1: Verifica que el resultado sea el esperado (Balance Positivo)
try {
    const resultado = calcularBalance(1000, 300);
    assert.strictEqual(resultado, 700, "Prueba 1 (Balance Positivo) falló. Esperado: 700");
    console.log(" Prueba 1: Balance positivo (PASSED)");
} catch (error) {
    console.error(` Prueba 1: ${error.message}`);
    process.exit(1);
}

// Prueba 2: Verifica un caso extremo (Balance Cero)
try {
    const resultado = calcularBalance(500, 500);
    assert.strictEqual(resultado, 0, "Prueba 2 (Balance Cero) falló. Esperado: 0");
    console.log(" Prueba 2: Balance cero (PASSED)");
} catch (error) {
    console.error(` Prueba 2: ${error.message}`);
    process.exit(1);
}

console.log("Todas las pruebas pasaron. Proceso de CI exitoso.");