import http from 'k6/http';
import { check } from 'k6';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import {
  AWSConfig,
  S3Client,
} from 'https://jslib.k6.io/aws/0.12.3/s3.js';

const s3 = new S3Client(new AWSConfig({
  region: "us-east-1",
  accessKeyId: __ENV.AWS_ACCESS_KEY_ID,
  secretAccessKey: __ENV.AWS_SECRET_ACCESS_KEY,
}));

// Obtendo valores de variáveis de ambiente ou usando padrões
const VUS = parseInt(__ENV.VUS) || 500; // Número de usuários virtuais simultâneos
const OUTPUT = __ENV.OUTPUT || 'raw-data.json'; // Nome do arquivo de saída
const HOST = __ENV.HOST || "localhost";

const bucketName = __ENV.BUCKET_NAME;

export const options = {
  scenarios: {
    fixed_iterations: {
      executor: "shared-iterations",
      vus: VUS,
      iterations: VUS * 500,
      maxDuration: "5m",
    },
  },
};

const endpoints = [
  '/',
  '/productpage',
  '/api/v1/products',
  '/api/v1/products/1',
  '/api/v1/products/1/reviews',
  '/api/v1/products/1/ratings',
];

function checkResponse(res) {
  check(res, { 'status was 200': (r) => r.status === 200 });
}

export default function () {
  for (const endpoint of endpoints) {
    const res = http.get(`http://${HOST}${endpoint}`);
    checkResponse(res);
  }
}

export function handleSummary(data) {
  try {
    const response = s3.putObject(bucketName, OUTPUT, JSON.stringify(data, null, 2));
    console.log(`Upload para S3 bem-sucedido! Resposta: ${JSON.stringify(response)}`);
  } catch (error) {
    console.error(`Erro ao enviar para S3: ${error.message}`);
  }

  return {
    [OUTPUT]: JSON.stringify(data), // Usa o nome do arquivo especificado em OUTPUT
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
