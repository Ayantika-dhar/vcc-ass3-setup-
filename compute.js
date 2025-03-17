function generateMatrix(size) {
    return Array.from({ length: size }, () =>
        Array.from({ length: size }, () => Math.floor(Math.random() * 100))
    );
}

function multiplyMatrices(A, B, size) {
    let result = Array(size).fill(0).map(() => Array(size).fill(0));

    for (let i = 0; i < size; i++) {
        for (let j = 0; j < size; j++) {
            let sum = 0;
            for (let k = 0; k < size; k++) {
                sum += A[i][k] * B[k][j];
            }
            result[i][j] = sum;
        }
    }
    return result;
}

const MATRIX_SIZE = 4000; // Change size for higher CPU load

console.log(`Starting CPU-intensive matrix multiplication (${MATRIX_SIZE}x${MATRIX_SIZE})...`);

while (true) {
    const A = generateMatrix(MATRIX_SIZE);
    const B = generateMatrix(MATRIX_SIZE);
    multiplyMatrices(A, B, MATRIX_SIZE);
}
